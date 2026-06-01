# Workflow: implement issue

This workflow is triggered when the dispatcher (team-lead) sends `"implement issue {url}"` to a teammate. It applies to any persona that implements GitHub issues — currently `lucos-developer`, `lucos-architect`, `lucos-ux`, `lucos-security`, `lucos-site-reliability`, `lucos-system-administrator`. Substitute your own persona name where this file uses `<persona>`.

Read this file in full at the start of the workflow. Do not work from memory of previous runs — the steps may have changed.

The dispatch contract — only work on issues you have been explicitly assigned, treat triage notifications as informational, raise drive-by findings as new issues — lives in [`references/scope-of-work.md`](../../references/scope-of-work.md). It applies whenever this workflow runs.

## Step 1 — Read the issue first

Before any code changes, **read the full issue body AND all comments**. Make two separate API calls — the body and comments are different endpoints:

```bash
# 1a. Body
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues/{number}

# 1b. Comments — must be fetched separately, not as a jq field on the body response
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues/{number}/comments
```

A jq-scoped body fetch (e.g. `--jq '{title: .title, body: .body}'`) does not include comments — they are on a separate endpoint. Skipping the comments call means you miss corrective context posted after the issue was filed (agreed approaches, scope changes, acceptance criteria additions).

Follow the **latest agreed direction**: this might be a comment from `lucas42`, or a suggestion from another commenter that `lucas42` has approved (via a +1 reaction or explicit agreement). When earlier suggestions conflict with later consensus, follow the later consensus. If in doubt about which direction was agreed, ask team-lead before proceeding.

## Step 2 — Post a starting comment

A brief, first-person overview of your approach, posted via `gh-as-agent` as your persona. Use the heredoc pattern (see [`references/agent-github-identity.md`](../../references/agent-github-identity.md)):

```bash
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues/{number}/comments \
    --method POST \
    --field body="$(cat <<'ENDBODY'
Brief, first-person overview of your approach. Concrete and concise — what
you're going to do, in what order, and any concerns you want to flag up front.
ENDBODY
)"
```

For bodies that contain `{owner}/{repo}` or other curly-brace placeholders, **or that begin with an `@`-mention** (e.g. a `@lucas42` ping comment), use the file-backed pattern (`-F body=@file`) from [`references/issue-creation.md`](../../references/issue-creation.md) instead — `gh api` silently corrupts curly-brace placeholders and mangles a leading `@` inside `--field body=`, so the heredoc `--field` form fails for both.

## Step 3 — Start from an up-to-date main branch

Before creating a feature branch, always pull the latest main:

```bash
git checkout main && git pull origin main
git checkout -b descriptive-branch-name
```

This prevents the PR from being "behind main" — which blocks auto-merge on repos with strict branch protection and requires a manual rebase after the fact.

## Step 4 — Implement the changes

Read the codebase first to understand existing patterns, conventions, and architecture. Use `find`, `grep`, and file reads to orient yourself. Match the style and structure already in use.

If the service runs in Docker, **verify the build locally before pushing.** Run `docker build` and `docker run` (or `docker compose up`) and confirm the container starts, passes its healthcheck, and behaves as expected. Don't rely on CI or production to catch container-level issues — a broken build pushed to `main` triggers an immediate production deploy and can cause a crash-loop.

Persona-specific implementation guidance (e.g. the developer's testing rules, the architect's ADR conventions) lives in the persona file or in a persona-specific reference. This workflow does not duplicate it.

## Step 5 — Commit using `git-as-agent`

Always use the `git-as-agent` wrapper for every commit-writing operation. See [`references/agent-github-identity.md`](../../references/agent-github-identity.md) for the wrapper rules.

Reference the issue in commits (`Refs #N`) and reserve closing keywords (`Closes #N`, `Fixes #N`) for the PR body.

For breaking changes, use the `BREAKING CHANGE:` footer or a `!` after the type (e.g. `feat!:`) — `semantic-release` requires a machine-readable token, not prose.

## Step 6 — Push and create a pull request

Use `~/sandboxes/lucos_agent/create-pr` — **never** call `gh-as-agent ... pulls` directly and **never** use `gh pr create`. The `create-pr` script creates the PR and automatically requests lucas42 as a reviewer if the repo is supervised. Combining both steps in one script means the reviewer request cannot be forgotten.

```bash
BODY_FILE=$(mktemp)
cat > "$BODY_FILE" <<'ENDBODY'
Closes #N

Brief description of what changed and why. Link to relevant issues, ADRs, or
prior art if useful.

## Test plan
- [ ] Bulleted checklist of how the change was verified.
ENDBODY

~/sandboxes/lucos_agent/create-pr \
    --app <persona> \
    --repo {repo} \
    --title "Short, descriptive title" \
    --body-file "$BODY_FILE" \
    --head your-branch-name \
    --base main

rm "$BODY_FILE"
```

The script prints the PR URL on success.

## Step 7 — Re-request reviewer after pushing fixes

`create-pr` handles the *initial* reviewer request automatically at PR creation: it adds `lucas42` on supervised repos and adds nobody on unsupervised repos.

The one situation where you must manually call `POST /requested_reviewers` yourself is **after pushing a fix in response to a CHANGES_REQUESTED review**. Submitting CHANGES_REQUESTED removes the reviewer from `requested_reviewers`, so without a fresh request the fixed PR falls out of their review queue.

**Pick the reviewer to re-request from the actual review history — do not hard-code a name.**

```bash
# 1. Find the reviewer who submitted CHANGES_REQUESTED:
~/sandboxes/lucos_agent/gh-as-agent --app <persona> \
    repos/lucas42/{repo}/pulls/{number}/reviews \
    --jq '[.[] | select(.state == "CHANGES_REQUESTED")] | last | .user.login'

# 2. Re-request that exact reviewer:
~/sandboxes/lucos_agent/gh-as-agent --app <persona> \
    repos/lucas42/{repo}/pulls/{number}/requested_reviewers \
    --method POST \
    -f 'reviewers[]=<reviewer-login-from-step-1>'
```

The login will typically be `lucas42` (supervised repos only, when he has personally reviewed) or `lucos-code-reviewer` (after the bot has submitted CHANGES_REQUESTED on any repo).

**Never request a reviewer who has not already reviewed the PR.** Specifically: do not request `lucas42` on an unsupervised repo — he was not added at PR creation, so there is nothing to re-engage. Hard-coding `lucas42` in this step pollutes his review queue with PRs he never volunteered to review.

## Step 8 — Comment on unexpected obstacles

If you hit something that might block completion — a dependency issue, an architectural question, a test environment problem — post a comment on the issue immediately. Don't silently work around problems without flagging them.

## Step 9 — Drive the PR review loop

After opening the PR, you are responsible for driving the review loop defined in [`pr-review-loop.md`](../../pr-review-loop.md). Send a message to `lucos-code-reviewer` via **`SendMessage` with `to: "lucos-code-reviewer"`** to request a review, address any feedback, and handle specialist reviews if requested. **Do NOT use the `Agent` tool to spawn a fresh `lucos-code-reviewer` (or any other `lucos-*`) subagent** — they are already teammates on the running team; spawning them via `Agent` bypasses the team flow. See [`references/teammate-communication.md`](../../references/teammate-communication.md) § "Don't spawn teammates as subagents".

**Do not report back** to whoever asked you to do the work until the review loop completes (approval or 5-iteration cap).

**This applies to drive-by PRs too.** If you open a secondary PR during implementation (e.g. a doc fix, a convention correction), that PR follows the same self-driven loop — send the review request to `lucos-code-reviewer` directly. Do not ask the coordinator or team-lead to route it for you; they are not in the routing path.

**Never merge PRs yourself** — they are merged either automatically (via the auto-merge workflow) or by a human. Just report the approval.

## Step 10 — Verify state before reporting it

Never report PR state (open, merged, awaiting review, approved) from memory. Query the GitHub API for the PR's current state immediately before any status report. Conversation memory drifts within minutes of CI or review activity — stale state is worse than no state.

## What you don't do

- **Don't close issues manually.** Issues are closed automatically via closing keywords in merged PRs.
- **Don't manage or triage issues.** That's the coordinator's job.
- **Don't approve your own PRs.** Create the PR and let the review process handle it.
- **Don't touch labels.** See [`references/label-workflow.md`](../../references/label-workflow.md).
- **Don't pick up a second issue in the same session** unless explicitly dispatched. Report back when the first one is done; the dispatcher decides what's next.

## Persona-specific extensions

Personas may layer on top of this workflow with their own conventions:

- **lucos-developer** — testing rules, the "let's try it" bias, don't get stuck in analysis paralysis.
- **lucos-architect** — implementation work is typically ADRs and documentation; reads ADR conventions from its own persona file.
- **lucos-ux** — frontend-led work, accessibility checks, copywriting conventions.

Persona-specific guidance must not contradict the steps above.
