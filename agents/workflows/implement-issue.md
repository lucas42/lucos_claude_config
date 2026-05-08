# Workflow: implement issue

This workflow is triggered when the dispatcher (team-lead) sends `"implement issue {url}"` to a teammate. It applies to any persona that implements GitHub issues — currently `lucos-developer`, `lucos-architect`, `lucos-ux`. Substitute your own persona name where this file uses `<persona>`.

Read this file in full at the start of the workflow. Do not work from memory of previous runs — the steps may have changed.

## Step 1 — Read the issue first

Before any code changes, **read the full issue body AND all comments (including reactions)**. Comments often contain critical context — agreed approaches, corrections, additional scope discovered after filing.

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

For bodies that contain `{owner}/{repo}` or other curly-brace placeholders, use the file-backed pattern from [`references/issue-creation.md`](../../references/issue-creation.md) instead — the `gh api` template substitution will silently corrupt placeholders inside `--field body=`.

## Step 3 — Start from an up-to-date main branch

Before creating a feature branch, always pull the latest main:

```bash
git checkout main && git pull origin main
git checkout -b descriptive-branch-name
```

This prevents the PR from being "behind main" — which blocks auto-merge on repos with strict branch protection and requires a manual rebase after the fact.

## Step 4 — Implement the changes

Read the codebase first to understand existing patterns, conventions, and architecture. Use `find`, `grep`, and file reads to orient yourself. Match the style and structure already in use.

Persona-specific implementation guidance (e.g. the developer's testing rules, the architect's ADR conventions) lives in the persona file or in a persona-specific reference. This workflow does not duplicate it.

## Step 5 — Commit using `git-as-agent`

Always use the `git-as-agent` wrapper for every commit-writing operation. See [`references/agent-github-identity.md`](../../references/agent-github-identity.md) for the wrapper rules.

Reference the issue in commits (`Refs #N`) and reserve closing keywords (`Closes #N`, `Fixes #N`) for the PR body.

For breaking changes, use the `BREAKING CHANGE:` footer or a `!` after the type (e.g. `feat!:`) — `semantic-release` requires a machine-readable token, not prose.

## Step 6 — Push and create a pull request

Use `gh-as-agent` — never `gh pr create`:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/pulls \
    --method POST \
    -f title="Short, descriptive title" \
    -f head="your-branch-name" \
    -f base="main" \
    --field body="$(cat <<'ENDBODY'
Closes #N

Brief description of what changed and why. Link to relevant issues, ADRs, or
prior art if useful.

## Test plan
- [ ] Bulleted checklist of how the change was verified.
ENDBODY
)"
```

## Step 7 — Request lucas42 as reviewer on supervised repos

Immediately after creating any PR, run `~/sandboxes/lucos_agent/check-unsupervised {repo}`:

- **Exit 0 (unsupervised)** — auto-merge handles approvals, no action needed.
- **Exit 1 (supervised)** — lucas42 needs to review:
  ```bash
  ~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/pulls/{number}/requested_reviewers \
      --method POST \
      -f reviewers[]=lucas42
  ```

Always use the `check-unsupervised` script — never infer supervision status by reading workflow YAML or other repo files. The script consults configy, which is the single source of truth.

## Step 8 — Comment on unexpected obstacles

If you hit something that might block completion — a dependency issue, an architectural question, a test environment problem — post a comment on the issue immediately. Don't silently work around problems without flagging them.

## Step 9 — Drive the PR review loop

After opening the PR, you are responsible for driving the review loop defined in [`pr-review-loop.md`](../../pr-review-loop.md). Send a message to `lucos-code-reviewer` to request a review, address any feedback, and handle specialist reviews if requested.

**Do not report back** to whoever asked you to do the work until the review loop completes (approval or 5-iteration cap).

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
