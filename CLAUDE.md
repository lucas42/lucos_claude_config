# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) for all projects in this environment.

## Lucos Infrastructure Reference

A reference for AI agents working on any lucos project. Covers deployment infrastructure, CI/CD, and conventions.

---

## Environment Variables & lucos_creds

Secrets and environment-varying config are managed by a service called **lucos_creds**. To write the local development `.env` file, run:

```bash
scp -P 2202 "creds.l42.eu:${PWD##*/}/development/.env" .
```

This is aliased as `localcreds` in the user's shell, but that alias is not available to Claude — use the raw command above.

### Standard vars always provided by lucos_creds

Every project gets these automatically:

| Variable | Description |
|---|---|
| `SYSTEM` | The system name (e.g. `lucos_photos`) |
| `ENVIRONMENT` | `development` or `production` |
| `PORT` | The port this service is exposed on |
| `APP_ORIGIN` | The public-facing base URL |

### Variable naming conventions

- External event infrastructure: `LOGANNE_ENDPOINT` (not `LUCOS_LOGANNE_URL` or similar)
- Contacts API: `LUCOS_CONTACTS_URL`

### What goes where

- **Hardcode in `docker-compose.yml`**: non-sensitive values that never vary between environments (internal service URLs, fixed usernames, database names)
- **lucos_creds (`.env`)**: sensitive values and anything that varies between dev and production

Avoid constructing compound values (e.g. `DATABASE_URL`) in docker-compose using variable interpolation — the CI build step only has access to a dummy `PORT` and will fail if other variables are referenced. Instead, construct them in application code at startup (e.g. SQLAlchemy's `URL.create()`).

---

## Docker & Docker Compose

### Container naming

- `container_name` must be set on every container
- Names must follow the pattern `lucos_<project>_<role>` (e.g. `lucos_photos_api`, `lucos_photos_postgres`)

### Image naming (built containers only)

- Set `image:` on any container built from a Dockerfile
- Pattern: `lucas42/lucos_<project>_<role>` (e.g. `lucas42/lucos_photos_api`)

### Environment variables in compose

**Do not use `env_file`** — it breaks the CI build step.

Instead, declare every environment variable explicitly in the `environment` section using **array syntax**. This makes it clear which containers use which variables, and allows pass-through vars (sourced from the host environment / `.env` file) without specifying their values:

```yaml
environment:
  - SYSTEM                          # pass-through from host env
  - POSTGRES_PASSWORD               # pass-through from host env
  - POSTGRES_USER=photos            # hardcoded value
  - REDIS_URL=redis://redis:6379    # hardcoded value
```

Dictionary syntax cannot express pass-through vars without a value, so always use array syntax in `environment`.

Note: Docker Compose still reads `.env` for **compose-level** variable substitution (e.g. `${PORT}` in `ports:`) even without `env_file` — this is a separate mechanism and is fine to use.

### Build context

When multiple services share code (e.g. a shared Python package), set the build context to the repo root and specify the Dockerfile path explicitly:

```yaml
build:
  context: .
  dockerfile: api/Dockerfile
```

The Dockerfile can then `COPY shared/ /shared/` from the repo root.

### Volumes

Always declare every volume explicitly — both in the service's `volumes:` mount and in the top-level `volumes:` section. Never rely on anonymous volumes created implicitly by a Docker image's `VOLUME` directive.

Anonymous volumes don't receive Docker Compose project labels, which breaks `lucos_backups` monitoring.

```yaml
services:
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data        # explicit mount — never omit this

volumes:
  redis_data:                   # always declare at top level
```

Every named volume must also be added to **`lucos_configy/config/volumes.yaml`** with a description and `recreate_effort`. Docker Compose names volumes as `<project>_<volume_name>` (e.g. `lucos_photos_redis_data`). Valid `recreate_effort` values:

| Value | Meaning |
|---|---|
| `automatic` | Can be fully regenerated automatically |
| `small` | Small technical effort to recreate |
| `tolerable` | Loss would be tolerable |
| `considerable` | Considerable effort to recreate |
| `huge` | Huge effort / primary source data |
| `remote` | Remote mount from elsewhere — set `skip_backup: true` |

### Networking

- HTTP traffic is proxied through a shared Nginx reverse proxy; TLS is terminated externally
- Services are exposed on `${PORT}`, configured per-environment via lucos_creds
- Containers on the same Docker Compose network communicate via service name as hostname

---

## CircleCI

When a project has no tests, the standard `.circleci/config.yml` is:

```yaml
version: 2.1
orbs:
  lucos: lucos/deploy@0
workflows:
  version: 2
  build-deploy:
    jobs:
      - lucos/build-amd64
      - lucos/deploy-avalon:
          serial-group: << pipeline.project.slug >>/deploy-avalon
          requires:
            - lucos/build-amd64
          filters:
            branches:
              only:
                - main
```

When a project has tests, add a `test` job running **in parallel** with `build-amd64`; both must pass before deploy. Tests run on all branches (no filter), deploy only on `main`.

**Self-contained tests** (e.g. FastAPI + SQLite in-memory — no real DB or env file needed):

```yaml
jobs:
  test:
    docker:
      - image: cimg/python:3.14
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: pip install -e shared/ -r api/requirements.txt -r api/requirements-test.txt
      - run:
          name: Run tests
          command: cd api && pytest
workflows:
  version: 2
  build-deploy:
    jobs:
      - test
      - lucos/build-amd64
      - lucos/deploy-avalon:
          serial-group: << pipeline.project.slug >>/deploy-avalon
          requires:
            - test
            - lucos/build-amd64
          filters:
            branches:
              only:
                - main
```

**Tests needing a real database** (e.g. Django — see lucos_contacts for full example): use `cimg/base:current` + `setup_remote_docker`, fetch a test `.env` from `creds.l42.eu:<repo>/test/.env`, and run via `docker compose --profile test up test --build --exit-code-from test`.

- The `lucos/build-amd64` job builds and pushes Docker images
- The `lucos/deploy-avalon` job deploys to the server, but only on `main`
- The CI build step has access to a dummy `PORT` only — no other env vars are available during build

---

## Python / FastAPI Testing

See [`python-testing.md`](python-testing.md) for FastAPI + SQLAlchemy testing patterns and gotchas.

---

## GitHub Credentials for AI Agents

When interacting with GitHub (creating issues, posting comments, etc.), authenticate as the appropriate GitHub App rather than using personal credentials.

Canonical identity data for all personas (App ID, Installation ID, bot user ID, bot name, display name, PEM variable) is stored in `~/sandboxes/lucos_agent/personas.json`. This is the single source of truth — refer to it rather than duplicating values in documentation or code.

Each persona must use its own dedicated GitHub App. The `--app` flag is **required** — there is no default. The correct app slug is passed as `--app <slug>` to both `get-token` and `gh-as-agent`. Omitting `--app` will result in an error.

**Important:** Git and GitHub API calls must be made within a persona context. The dispatcher itself cannot make git commits or GitHub API calls — any task requiring these must be handed off to the appropriate persona via the Task tool.

### Setup

The `get-token` script lives in `~/sandboxes/lucos_agent/`. It requires a `.env` file in that directory (containing keys for all apps), pulled from lucos_creds:

```bash
scp -P 2202 "creds.l42.eu:lucos_agent/development/.env" ~/sandboxes/lucos_agent/
```

### Making GitHub API calls

Use the `gh-as-agent` wrapper script instead of calling `gh api` directly. It handles token generation internally. `--app` must be the first argument:

```bash
# lucos-issue-manager persona
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues \
    --method POST \
    -f title="Issue title" \
    -f body="Body text here"

# lucos-code-reviewer persona
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer repos/lucas42/{repo}/pulls/{pr}/reviews \
    --method POST \
    -f body="Review comment" \
    -f event="APPROVE"

# lucos-system-administrator persona
~/sandboxes/lucos_agent/gh-as-agent --app lucos-system-administrator repos/lucas42/{repo}/issues \
    --method POST \
    -f title="Issue title" \
    -f body="Body text here"
```

All `gh api` flags and arguments are passed through directly. There is no need to generate or manage tokens manually.

---

## Working on GitHub Issues

When assigned or asked to work on a GitHub issue, follow this workflow:

### 1. Post a starting comment

Before beginning any code changes, post a comment on the issue using `gh-as-agent` to say you're starting work and give a brief overview of your approach. Write it in the first person, e.g.:

> I'm going to tackle this by updating the API handler to validate the input before passing it to the database layer, then add a test to cover the new behaviour.

### 2. Create pull requests using gh-as-agent

Pull requests must be created using `gh-as-agent`, exactly like issue comments and any other GitHub API calls — **never** using `gh pr create` directly (which uses personal credentials instead of the correct bot identity):

```bash
~/sandboxes/lucos_agent/gh-as-agent repos/lucas42/{repo}/pulls \
    --method POST \
    -f title="Fix the thing" \
    -f head="my-branch" \
    -f base="main" \
    -f body="Closes #42\n\n..."
```

### 3. Tag commits and pull requests with the issue

Every commit and pull request made as part of the work should reference the issue number. In commit messages, include the issue reference (e.g. `Refs #42`). In the pull request body, use one of GitHub's standard closing keywords so the issue is automatically closed when the PR is merged into `main`:

```
Closes #42
```

The full list of supported keywords is: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved` — followed by the issue reference (e.g. `Fixes #42` or `Resolves lucas42/lucos_example#42`).

**Note:** GitHub does not process closing keywords when a bot merges a PR. Repos with the code reviewer auto-merge workflow handle this automatically (see "Code reviewer auto-merge" under GitHub Config). For repos without that workflow, closing keywords still serve as documentation of intent — a human merging the PR will trigger the auto-close.

### 3. Comment on unexpected obstacles

If you hit a significant unexpected obstacle during the work — especially one that risks not being able to finish without further input — post a follow-up comment on the issue explaining what you've encountered. Don't silently get stuck or work around something without flagging it.

### 4. Don't close issues yourself

Issues should be closed automatically via the closing keyword in the merged PR. Do not close issues manually unless explicitly instructed to (e.g. told that an issue is now obsolete).

---

## GitHub Config

### CodeQL (`.github/workflows/codeql-analysis.yml`)

Only include languages actually present in the repo. Remove any languages copied from another project that don't apply (e.g. `javascript` in a Python-only project).

### Dependabot (`.github/dependabot.yml`)

Specify the correct directories for each ecosystem — these must match where the actual files live, not convention from the source project:

- `pip`: one entry per `requirements.txt` / `pyproject.toml` location (e.g. `/api`, `/worker`, `/shared`)
- `docker`: one entry per `Dockerfile` location (e.g. `/api`, `/worker`)
- `github-actions`: always `directory: "/"`

Remove any `ignore` rules that were specific to the source project's framework (e.g. Django's `asgiref`).

### Dependabot auto-merge (`.github/workflows/auto-merge.yml`)

Standard file, no project-specific changes needed.

### Code reviewer auto-merge (`.github/workflows/code-reviewer-auto-merge.yml`)

This workflow enables auto-merge on PRs approved by `lucos-code-reviewer[bot]`. Currently deployed to `lucos_photos` only; will be rolled out to other repos over time.

**How it works:**

1. **`auto-merge` job** — triggers on `pull_request_review: submitted`. If the review is an approval from `lucos-code-reviewer[bot]` (verified by both login and numeric user ID to prevent impersonation), it runs `gh pr merge --auto --merge`.
2. **`close-linked-issues` job** — triggers on `pull_request: closed`. If the PR was merged by `lucos-code-reviewer[bot]`, it queries GitHub's GraphQL `closingIssuesReferences` field and closes each linked open issue via the API.

The `close-linked-issues` job is necessary because **GitHub does not process closing keywords (e.g. `Closes #N`) when any bot merges a PR** — this is a platform limitation, not specific to `GITHUB_TOKEN` or GitHub Actions. The workaround uses `closingIssuesReferences`, which GitHub parses from the PR body regardless of who merges.

**Prerequisites for each repository:**

1. **Repository secrets** — two secrets must be set:
   - `CODE_REVIEWER_APP_ID` — the lucos-code-reviewer App ID (see `personas.json`)
   - `CODE_REVIEWER_PRIVATE_KEY` — the lucos-code-reviewer RSA private key (from lucos_creds, with newlines restored from the space-flattened format)
2. **GitHub App permissions** — `lucos-code-reviewer` must have these permissions on its installation:
   - `Contents: Read & write` (required to merge PRs)
   - `Pull requests: Read & write` (required to enable auto-merge)
   - `Issues: Read & write` (required to close linked issues)
3. **Repository setting** — "Allow auto-merge" must be enabled in the repo's settings

**Reference implementation:** `lucos_photos/.github/workflows/code-reviewer-auto-merge.yml`

---

## Maintaining This Environment

### Version-controlled `~/.claude` changes

`~/.claude` is tracked in the `lucas42/lucos_claude_config` git repository. Whenever changes are made to files under `~/.claude` that are part of this repo (e.g. `CLAUDE.md` itself, persona instruction files), those changes must be committed and pushed:

```bash
cd /home/lucas.linux/.claude
git add <changed files>
git commit -m "Description of change"
git push
```

### VM environment changes

`lucos_agent_coding_sandbox` (at `~/sandboxes/lucos_agent_coding_sandbox`) is responsible for provisioning the VM this environment runs in. Whenever changes are made to the broader VM environment — e.g. SSH config, installed packages, system-level configuration — those changes must also be reflected in `lucos_agent_coding_sandbox` so the VM can be reproduced from scratch. Update the relevant files (e.g. `lima.yaml`, `setup-repos.sh`, `ssh/`) and commit and push the changes to that repo.

### Requesting missing tools

If you discover that a tool needed to complete a task is not installed in this environment (e.g. a language runtime, build tool, or CLI), raise a GitHub issue on `lucas42/lucos_agent_coding_sandbox` requesting it be added. Include:
- What tool is missing and what version (if relevant)
- Which task or project revealed the gap
- Why having it locally matters (e.g. faster feedback than waiting for CI)

Do this proactively — don't silently work around missing tools without flagging them.

---

## The `/_info` Endpoint

Every lucos HTTP service must expose a `/_info` endpoint with no authentication. It is used by monitoring and a homepage app.

Response is JSON with the following fields:

| Field | Type | Description |
|---|---|---|
| `system` | string | The system name — read from `SYSTEM` env var |
| `checks` | object | Live health checks (evaluated at request time). Each key is a check name; value has `ok` (bool) and `techDetail` (string) |
| `metrics` | object | Live metrics (evaluated at request time). Each key is a metric name; value has `value` (number) and `techDetail` (string) |
| `ci` | object | CI info: `{"circle": "gh/lucas42/<repo_name>"}` |
| `icon` | string | Path to the service's icon endpoint |
| `network_only` | bool | `true` if the UI requires a network connection to render; `false` if it works offline (e.g. via service workers) |
| `title` | string | Human-readable service name |
| `show_on_homepage` | bool | Whether to show this service on the lucos homepage |
| `start_url` | string | URL path to the UI entry point |

`checks` and `metrics` can be empty objects if there is nothing meaningful to report yet.

Example:

```json
{
  "system": "lucos_example",
  "checks": {
    "db-reachable": {
      "ok": true,
      "techDetail": "Checks whether a connection to PostgreSQL can be established"
    }
  },
  "metrics": {
    "photo-count": {
      "value": 42318,
      "techDetail": "Total number of photos stored"
    }
  },
  "ci": {
    "circle": "gh/lucas42/lucos_example"
  },
  "icon": "/icon",
  "network_only": true,
  "title": "Example",
  "show_on_homepage": true,
  "start_url": "/"
}
```

---

## Monitoring Status API

The lucos monitoring system exposes a machine-readable status endpoint for agents to check the health of all lucos services:

```
GET https://monitoring.l42.eu/api/status
```

No authentication required. Returns JSON.

### Response structure

```json
{
  "systems": {
    "example.l42.eu": {
      "name": "lucos_example",
      "healthy": true,
      "checks": {
        "fetch-info": {
          "ok": true,
          "techDetail": "Fetches /_info"
        }
      },
      "metrics": {}
    }
  },
  "summary": {
    "total_systems": 1,
    "healthy": 1,
    "erroring": 0,
    "unknown": 0
  }
}
```

### Field reference

**Top level:**

| Field | Type | Description |
|---|---|---|
| `systems` | object | Per-system status, keyed by hostname |
| `summary` | object | Aggregate counts across all systems |

**Each system (keyed by hostname):**

| Field | Type | Description |
|---|---|---|
| `name` | string | The system name (e.g. `lucos_photos`). `"unknown"` if the system's `/_info` could not be fetched |
| `healthy` | bool | `true` if all checks pass, `false` if any check is failing. Neither true nor false if status is unknown |
| `checks` | object | Health checks for this system, keyed by check name. Each check has `ok` (bool or the string `"unknown"`), `techDetail` (string), and optionally `debug` (string with error details when `ok` is false) |
| `metrics` | object | Metrics for this system, as reported by its `/_info` endpoint |

**Summary:**

| Field | Type | Description |
|---|---|---|
| `total_systems` | number | Total number of monitored systems |
| `healthy` | number | Count of systems where all checks pass |
| `erroring` | number | Count of systems with at least one failing check |
| `unknown` | number | Count of systems whose status could not be determined |

---

## Dispatching All Agents

When the user says **"all agents, review your issues"**, dispatch agents in three sequential phases using the Task tool. Do not ask for clarification — immediately begin Phase 1. You must wait for each phase to fully complete before starting the next.

### Phase 1 (parallel — run immediately)

Launch these two agents concurrently in the same response:

1. `lucos-issue-manager` — "review your issues"
2. `lucos-code-reviewer` — "review your issues"

**Wait for both to complete before proceeding.**

Rationale: the issue manager runs first to assign `owner:` labels to unowned issues so that Phase 2 agents pick up fresh work. The code reviewer is independent of the issue pipeline and can run in parallel.

### Phase 2 (parallel — after Phase 1 completes)

Once Phase 1 is done, launch these four agents concurrently in the same response:

3. `lucos-architect` — "review your issues"
4. `lucos-system-administrator` — "review your issues"
5. `lucos-security` — "review your issues"
6. `lucos-site-reliability` — "review your issues"

**Wait for all four to complete before proceeding.**

Rationale: these agents often add comments or partial work rather than immediately closing issues, which may leave issues needing reassignment or label transitions.

### Phase 3 (sequential — after Phase 2 completes)

Once Phase 2 is done, launch one final agent:

7. `lucos-issue-manager` — "review your issues"

Rationale: the issue manager reviews any issues that Phase 2 agents touched, reassigns or transitions labels as appropriate, and tidies up anything left in an intermediate state.

Each agent knows how to discover its own backlog via its assigned labels.

---

## Dispatching "Implement the Next Issue"

When the user says **"implement the next issue"** (or similar phrasing about picking up the next implementation task), follow this process. Do not ask for clarification — immediately begin Step 1.

### Step 1: Find the next issue

Run the global prioritisation script:

```bash
~/sandboxes/lucos_agent/get-next-implementation-issue
```

This searches across **all** repositories and **all** personas for the single highest-priority `agent-approved`, non-blocked issue. It prints three lines:

1. The owner label (e.g. `owner:lucos-developer`)
2. The issue number and title (e.g. `#42 Fix the thing`)
3. The issue URL

If the script reports no implementable issues, tell the user there is nothing ready to implement right now and stop.

### Step 2: Dispatch the correct persona

Extract the persona name from the owner label (strip the `owner:` prefix) and launch that persona via the Task tool. Pass the **specific issue URL** so the persona knows exactly what to work on. For example:

> "implement issue https://github.com/lucas42/lucos_photos/issues/42"

Wait for the persona to complete.

**Why the dispatcher picks the issue:** All implementation agents run in the same sandbox, so dispatching multiple personas to different repos simultaneously would risk filesystem conflicts. The dispatcher controls sequencing by picking one issue at a time.

### Step 3: Check for a new PR

After the agent finishes, check its output to determine whether a pull request was created. Look for PR URLs (e.g. `https://github.com/lucas42/.../pull/N`) or explicit statements that a PR was opened.

### Step 4: Review loop (if a PR was created)

If no PR was created (e.g. the agent hit a blocker before opening a PR), skip this step.

If a PR was created, enter a review loop. Track the **iteration count** starting at 1.

**4a. Launch code review.**

Launch `lucos-code-reviewer` with a prompt to review the PR:

> "review PR https://github.com/lucas42/{repo}/pull/{number}"

Wait for it to complete.

**4b. Check the review outcome.**

If the code reviewer **approved** the PR, the loop is done — report success to the user and stop.

If the code reviewer **requested changes** and the iteration count is **less than 5**, continue to step 4c.

If the code reviewer **requested changes** and this is iteration **5**, stop the loop and tell the user:

> The PR at {url} has gone through 5 review iterations without approval. This likely indicates a mismatch in expectations that needs human judgement — please take a look.

**4c. Send the PR back to the implementation persona.**

Launch the **same persona** from Step 2 (the one that opened the PR) with a prompt to address the review feedback. For example:

> "address the code review feedback on PR https://github.com/lucas42/{repo}/pull/{number}"

Wait for it to complete, increment the iteration count, and go back to step 4a.
