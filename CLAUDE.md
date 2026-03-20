# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) for all projects in this environment.

## Commit Messages

Do not add `Co-Authored-By` trailers to git commits. The bot identity on each commit already makes authorship clear.

## Learning from Mistakes

When you fail to follow an instruction, do not apologise. Instead, suggest a concrete improvement to the instructions or environment that would prevent the same mistake from happening again. There is nothing wrong with making mistakes — but we should always learn from them.

When a mistake occurs in a routine task (ops checks, triage, issue review, etc.), prefer updating the relevant instruction files — persona files, skill files, triage procedures — rather than only updating agent memory. Memory is session context that may not persist reliably across conversations; instructions are what agents actually follow every run. If a mistake reveals a gap in a persona's standing instructions, fix the instructions.

**Writing a feedback memory is not a complete fix.** After saving a memory about a mistake, always ask: "does this also need an instruction update in a skill file, persona file, or other standing instruction?" If yes, make that update (or delegate it to the appropriate teammate) before considering the fix complete. A feedback memory records what went wrong; an instruction update prevents it from happening again. Do both.

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

## GitHub Credentials for AI Agents

When interacting with GitHub (creating issues, posting comments, etc.), authenticate as the appropriate GitHub App rather than using personal credentials.

Canonical identity data for all personas (App ID, Installation ID, bot user ID, bot name, display name, PEM variable) is stored in `~/sandboxes/lucos_agent/personas.json`. This is the single source of truth — refer to it rather than duplicating values in documentation or code.

Each persona must use its own dedicated GitHub App. The `--app` flag is **required** — there is no default. The correct app slug is passed as `--app <slug>` to both `get-token` and `gh-as-agent`. Omitting `--app` will result in an error.

**Important:** Git and GitHub API calls must be made within a persona context. The dispatcher itself cannot make git commits or GitHub API calls — any task requiring these must be handed off to the appropriate teammate via SendMessage.

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

### GitHub Projects API calls (PAT required)

GitHub Apps cannot access v2 user projects. For GitHub Projects interactions **only**, use the `gh-projects` wrapper instead of `gh-as-agent`:

```bash
# Query projects via GraphQL
~/sandboxes/lucos_agent/gh-projects graphql \
    -f query='{ viewer { projectsV2(first: 10) { nodes { id title } } } }'
```

**Do not use `gh-projects` for anything other than GitHub Projects.** All other GitHub API calls must use `gh-as-agent` with the appropriate `--app`.

### GitHub App limitations — things agents cannot do

Some GitHub operations require the **repo owner** (lucas42) to perform them in the GitHub web UI. Agents must not accept tasks for these — instead, tell the user what needs changing and why upfront:

- **GitHub App permission changes** (adding permissions like `actions:write`, `contents:write`): requires the app owner to update them in the GitHub Developer Settings UI, then the repo owner to approve the new permissions on each installation. There is no API for this.
- **`@dependabot` commands** (`recreate`, `rebase`, etc.): require push access to the repository. No agent app currently has push access.
- **Actions workflow re-runs**: require `actions:write` permission. `lucos-system-administrator` has this permission and can re-run workflows.
- **Branch protection rule changes**: require admin access to the repository.

When an agent discovers it lacks permissions for an action (e.g. a 403 response), it must **escalate immediately** with a clear explanation of what permission is missing and who can grant it — not retry, work around it, or silently drop the task.

### Making git commits as a persona

Use the `git-as-agent` wrapper script instead of passing `-c user.name=... -c user.email=...` flags manually on every git operation. It looks up the persona's identity from `personas.json` and prepends the correct `-c` flags automatically. `--app` must be the first argument:

```bash
~/sandboxes/lucos_agent/git-as-agent --app lucos-system-administrator commit -m "Fix something"
~/sandboxes/lucos_agent/git-as-agent --app lucos-site-reliability cherry-pick abc123
~/sandboxes/lucos_agent/git-as-agent --app lucos-developer commit --amend
~/sandboxes/lucos_agent/git-as-agent --app lucos-developer pull --rebase origin main
~/sandboxes/lucos_agent/git-as-agent --app lucos-developer rebase main
```

All remaining arguments are passed through to `git` directly. The wrapper handles the identity for any commit-writing operation — `commit`, `cherry-pick`, `commit --amend`, `pull --rebase`, `rebase`, etc. — ensuring the author and committer are always attributed to the correct bot, not the global git config.

**Never** use `git config user.name` or `git config user.email` — that would affect all future commits in the environment.

---

## Cross-Repository Issue References

When referencing GitHub issues or PRs in a different repository from comments, PR descriptions, or issue bodies, always use the fully-qualified format including the owner: "lucas42/<repo>#<number>" (e.g. "lucas42/lucos_arachne#86"). Without the `lucas42/` prefix, GitHub does not create a clickable link -- it renders as plain text.

Within the same repository, `#<number>` is sufficient.

**Never wrap issue or PR references in backticks.** Writing `` `#42` `` or `` `lucas42/lucos_contacts#537` `` prevents GitHub from auto-linking them -- they render as plain code-formatted text instead of clickable links. Issue references should always appear as bare text (e.g. #42, lucas42/lucos_contacts#537).

---

## Working on GitHub Issues

When assigned or asked to work on a GitHub issue, follow this workflow:

### 1. Post a starting comment

Before beginning any code changes, post a comment on the issue using `gh-as-agent` to say you're starting work and give a brief overview of your approach. Write it in the first person, e.g.:

> I'm going to tackle this by updating the API handler to validate the input before passing it to the database layer, then add a test to cover the new behaviour.

### 2. Start from an up-to-date main branch

Before creating a feature branch, always pull the latest main: `git checkout main && git pull origin main`, then branch from there. This prevents the PR from being "behind main" — which blocks auto-merge on repos with strict branch protection and requires a manual rebase after the fact.

### 3. Create pull requests using gh-as-agent

Pull requests must be created using `gh-as-agent`, exactly like issue comments and any other GitHub API calls — **never** using `gh pr create` directly (which uses personal credentials instead of the correct bot identity):

```bash
~/sandboxes/lucos_agent/gh-as-agent repos/lucas42/{repo}/pulls \
    --method POST \
    -f title="Fix the thing" \
    -f head="my-branch" \
    -f base="main" \
    -f body="Closes #42\n\n..."
```

### 4. Tag commits and pull requests with the issue

Every commit and pull request made as part of the work should reference the issue number. In commit messages, include the issue reference (e.g. `Refs #42`). In the pull request body, use one of GitHub's standard closing keywords so the issue is automatically closed when the PR is merged into `main`:

```
Closes #42
```

The full list of supported keywords is: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved` — followed by the issue reference (e.g. `Fixes #42` or `Resolves lucas42/lucos_example#42`).

**Note:** GitHub does not process closing keywords when a bot merges a PR. Repos with the code reviewer auto-merge workflow handle this automatically (see `references/github-config.md`). For repos without that workflow, closing keywords still serve as documentation of intent — a human merging the PR will trigger the auto-close.

### 5. Comment on unexpected obstacles

If you hit a significant unexpected obstacle during the work — especially one that risks not being able to finish without further input — post a follow-up comment on the issue explaining what you've encountered. Don't silently get stuck or work around something without flagging it.

### 6. Don't close issues yourself

Issues should be closed automatically via the closing keyword in the merged PR. Do not close issues manually unless explicitly instructed to (e.g. told that an issue is now obsolete).

---

## After a PR is Created

After opening a pull request, implementation teammates are responsible for requesting their own code review. Send a message to the `lucos-code-reviewer` teammate directly, following the process in [`pr-review-loop.md`](pr-review-loop.md).

The dispatcher no longer orchestrates this — the review loop is handled peer-to-peer between the implementation teammate and the code reviewer.

Do not consider an implementation task complete until the review loop has finished.

---

## Bulk Cross-Repo Operations

When pushing commits to many repos simultaneously (e.g. rolling out a workflow change, bulk secret updates, convention fixes), **stagger them in batches of 3-5 repos with a few minutes between batches**. Do not push to all repos at once.

Each push triggers a CI build and deploy. Simultaneous deploys to the same production host saturate CPU and I/O, causing Docker healthcheck cascades, port binding failures, and service outages. Both the 2026-03-19 incident (PORT missing from .env under concurrent SFTP load) and the 2026-03-20 incident (avalon load spike to 40) were caused or worsened by pushing to ~30 repos simultaneously.

---

## Team Management

**Never shut down teammates unprompted.** Only shut down the team when the user explicitly asks. Idle teammates cost zero tokens — tokens are only spent when an agent processes a turn. Idle notifications are normal and do not mean the user is done. Silence from the user is not permission to act.

**Delegate the problem, not the solution.** When sending work to a teammate, describe what went wrong or what needs to change and why — do not prescribe the exact fix. Let the teammate decide the approach. They have domain expertise and will produce a better result when given the problem statement rather than a pre-written patch to apply.

When shutting down a team, send shutdown requests to all teammates and **wait for every teammate to confirm shutdown** before calling TeamDelete. Never delete a team while shutdown requests are still pending — that orphans processes.

---

## Maintaining This Environment

### Version-controlled `~/.claude` changes

`~/.claude` is tracked in the `lucas42/lucos_claude_config` git repository. Whenever changes need to be made to files under `~/.claude`, the dispatcher must **never** edit those files directly — all changes must be delegated to the appropriate teammate from the start via SendMessage. The teammate should make both the file edits and the commit, so it has full context of what changed and why.

Route to the appropriate teammate based on the type of change:
- **`lucos-issue-manager`**: workflow and process changes — persona instruction files, skills, routine documentation, issue lifecycle docs
- **`lucos-system-administrator`**: infrastructure and environment changes — `CLAUDE.md` itself, ops check files, environment config

Always commit to `main` and push. Do not create or use feature branches.

### VM environment changes

`lucos_agent_coding_sandbox` (at `~/sandboxes/lucos_agent_coding_sandbox`) is responsible for provisioning the VM this environment runs in. Whenever changes are made to the broader VM environment — e.g. SSH config, installed packages, system-level configuration — those changes must also be reflected in `lucos_agent_coding_sandbox` so the VM can be reproduced from scratch. Update the relevant files (e.g. `lima.yaml`, `setup-repos.sh`, `ssh/`) and commit and push the changes to that repo.

### Requesting missing tools

If you discover that a tool needed to complete a task is not installed in this environment (e.g. a language runtime, build tool, or CLI), raise a GitHub issue on `lucas42/lucos_agent_coding_sandbox` requesting it be added. Include:
- What tool is missing and what version (if relevant)
- Which task or project revealed the gap
- Why having it locally matters (e.g. faster feedback than waiting for CI)

Do this proactively — don't silently work around missing tools without flagging them.

---

## Reference Files

Detailed conventions are documented in `~/.claude/references/`. Consult these when working on the relevant infrastructure:

| File | Contents |
|---|---|
| [`references/docker-conventions.md`](references/docker-conventions.md) | Container naming, volumes, env vars, networking, healthcheck gotchas |
| [`references/circleci-conventions.md`](references/circleci-conventions.md) | Standard CI config templates, CircleCI API access |
| [`references/info-endpoint-spec.md`](references/info-endpoint-spec.md) | `/_info` endpoint fields, tiers, and example |
| [`references/github-config.md`](references/github-config.md) | CodeQL, Dependabot, auto-merge workflow, PEM key formatting |
| [`references/ssh-production.md`](references/ssh-production.md) | SSH conventions, host list, safety warnings, read-only commands |
| [`references/monitoring-loganne.md`](references/monitoring-loganne.md) | Monitoring API schema, Loganne read/write, planned maintenance events |
| [`python-testing.md`](python-testing.md) | FastAPI + SQLAlchemy testing patterns and gotchas |
