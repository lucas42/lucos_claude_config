# GitHub Workflow Reference

## GitHub Credentials for AI Agents

When interacting with GitHub (creating issues, posting comments, etc.), authenticate as the appropriate GitHub App rather than using personal credentials.

Canonical identity data for all personas (App ID, Installation ID, bot user ID, bot name, display name, PEM variable) is stored in `~/sandboxes/lucos_agent/personas.json`. This is the single source of truth — refer to it rather than duplicating values in documentation or code.

Each persona must use its own dedicated GitHub App. The `--app` flag is **required** — there is no default. The correct app slug is passed as `--app <slug>` to both `get-token` and `gh-as-agent`. Omitting `--app` will result in an error.

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

**Warning: `gh api` silently rewrites `{owner}`, `{repo}`, and `{owner}/{repo}` tokens inside `-f body="..."` values.** GitHub's `gh` CLI performs template substitution on these patterns — so prose like "see `repos/lucas42/lucos_foo/issues`" or "`{owner}/{repo}` pattern" will be silently mangled to real repo values. If your issue body, comment, or PR description contains any of these patterns, use a file-backed body instead:

```bash
cat > /tmp/body.md <<'EOF'
Body text here — {owner}/{repo} patterns are safe in heredoc files.
EOF
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues \
    --method POST \
    -f title="Issue title" \
    --field body=@/tmp/body.md
```

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
- **Branch protection rule changes**: `lucos-system-administrator` has `administration: write` and CAN modify branch protection rules (required status checks, etc.) via the API. Do not use the `/repos/{owner}/{repo}/collaborators/{user}/permission` endpoint to pre-check this — it reflects collaborator status, not GitHub App installation permissions, and will falsely return `none`. Just make the API call directly and handle a 403 if it comes back.

When an agent discovers it lacks permissions for an action (e.g. a 403 response), it must **escalate immediately** with a clear explanation of what permission is missing and who can grant it — not retry, work around it, or silently drop the task.

### Marking draft PRs as ready for review

The REST API (`PATCH /repos/{owner}/{repo}/pulls/{number}` with `draft: false`) **does not work** — it silently ignores the `draft` field. Use the GraphQL `markPullRequestReadyForReview` mutation instead:

```bash
# First get the PR's node ID
PR_NODE_ID=$(~/sandboxes/lucos_agent/gh-as-agent --app lucos-developer \
  repos/lucas42/{repo}/pulls/{number} --jq '.node_id')

# Then mark it ready via GraphQL
~/sandboxes/lucos_agent/gh-as-agent --app lucos-developer graphql \
  -f query="mutation { markPullRequestReadyForReview(input: {pullRequestId: \"$PR_NODE_ID\"}) { pullRequest { isDraft } } }"
```

The `pull_requests: write` permission (which developer and other apps already have) is sufficient. Do **not** use `gh-projects` for this — that PAT only has `project` scope.

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

Every commit and pull request made as part of the work should reference the issue number. In commit messages, include the issue reference (e.g. `Refs #42`).

**Only use closing keywords (`Closes #42`, `Fixes #42`, etc.) in the PR body when the PR actually completes and should close the referenced issue.** Do not include a closing keyword if:
- The PR is a prerequisite or partial step toward an issue (use `Refs #42` instead)
- There is no issue being directly resolved by the PR
- The issue should remain open after the PR merges (e.g. further work is needed)

The full list of closing keywords is: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved` — followed by the issue reference (e.g. `Fixes #42` or `Resolves lucas42/lucos_example#42`). These trigger automatic issue closure on merge, so using them incorrectly will close issues prematurely.

**Note:** GitHub does not process closing keywords when a bot merges a PR. Repos with the code reviewer auto-merge workflow handle this automatically (see `references/github-config.md`). For repos without that workflow, closing keywords still serve as documentation of intent — a human merging the PR will trigger the auto-close.

### 5. Comment on unexpected obstacles

If you hit a significant unexpected obstacle during the work — especially one that risks not being able to finish without further input — post a follow-up comment on the issue explaining what you've encountered. Don't silently get stuck or work around something without flagging it.

### 6. Don't close issues yourself

Issues should be closed automatically via the closing keyword in the merged PR. Do not close issues manually unless explicitly instructed to (e.g. told that an issue is now obsolete).

---

## After a PR is Created

After opening a pull request, implementation teammates are responsible for requesting their own code review. Send a message to the `lucos-code-reviewer` teammate directly, following the process in [`pr-review-loop.md`](../pr-review-loop.md).

The dispatcher no longer orchestrates this — the review loop is handled peer-to-peer between the implementation teammate and the code reviewer.

Do not consider an implementation task complete until the review loop has finished.

---

## Bulk Cross-Repo Operations

When pushing commits to many repos simultaneously (e.g. rolling out a workflow change, bulk secret updates, convention fixes), **stagger them in batches of 3-5 repos with a few minutes between batches**. Do not push to all repos at once.

Each push triggers a CI build and deploy. Simultaneous deploys to the same production host saturate CPU and I/O, causing Docker healthcheck cascades, port binding failures, and service outages. Both the 2026-03-19 incident (PORT missing from .env under concurrent SFTP load) and the 2026-03-20 incident (avalon load spike to 40) were caused or worsened by pushing to ~30 repos simultaneously.
