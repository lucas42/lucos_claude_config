# Workflow: implement issue

This workflow is triggered when the dispatcher (team-lead) sends `"implement issue {url}"` to a teammate. It applies to any persona that implements GitHub issues — currently `lucos-developer`, `lucos-architect`, `lucos-ux`, `lucos-security`, `lucos-site-reliability`, `lucos-system-administrator`. Substitute your own persona name where this file uses `<persona>`.

Read this file in full at the start of the workflow. Do not work from memory of previous runs — the steps may have changed.

The dispatch contract — only work on issues you have been explicitly assigned, treat triage notifications as informational, raise drive-by findings as new issues — lives in [`references/scope-of-work.md`](../../references/scope-of-work.md). It applies whenever this workflow runs.

## Step 1 — Read the issue first

Before any code changes, **read the full issue body AND all comments**. The body and comments are different endpoints — **issue both calls in the same tool-call round, never sequentially**, so there is no gap where you send the first and move on without the second:

```bash
# 1a. Body
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues/{number}

# 1b. Comments — must be fetched separately, not as a jq field on the body response
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues/{number}/comments
```

A jq-scoped body fetch (e.g. `--jq '{title: .title, body: .body}'`) does not include comments — they are on a separate endpoint. Skipping the comments call means you miss corrective context posted after the issue was filed (agreed approaches, scope changes, acceptance criteria additions) — including a **dispatch comment added after triage**, which is exactly where a process requirement specific to this issue (e.g. "loop in a specialist before opening the PR") is most likely to live. Having correctly made both calls on a previous issue earlier in the same session does not carry forward — re-issue both, every time, even the tenth time this session.

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

## Step 3 — Implement in an isolated git worktree off a fresh `origin/main`

The working directory for each repo (`~/sandboxes/{repo}`) is **shared by all teammate agents**. A plain `git checkout -b` there is unsafe when another agent may be implementing in the same repo: a sibling can switch that shared HEAD between your `checkout` and your `commit`, so `git-as-agent commit` lands your work on *their* branch and your own branch pushes empty. Branching off a stale main is the other failure. **Both are avoided by doing all your work in a dedicated worktree** — a separate working directory with its own HEAD, branched off freshly-fetched `origin/main`.

**This applies to a dispatched issue in `lucos_claude_config` (`~/.claude`) too, and `CLAUDE.md` does not forbid it.** That file's "never hand-run any git command that writes to this shared checkout's working tree" governs commands that mutate the shared tree; `git worktree add` writes only `.git/worktrees/` metadata and a brand-new directory, and touches the shared tree not at all. `commit-claude-main` is for the direct-to-`main` path (coordinator edits to persona/skill/routine files) — reaching for it on a **dispatched** issue is a silent double failure: the work lands with no PR, so no closing keyword closes the ticket, and no reviewer ever sees it.

```bash
REPO={repo}; NUM={number}
MAIN="$HOME/sandboxes/$REPO"                  # shared checkout — only used to manage the worktree
WT="$HOME/sandboxes/.worktrees/$REPO-$NUM"    # your isolated working dir for this issue
BRANCH=descriptive-branch-name

git -C "$MAIN" fetch origin main
mkdir -p "$HOME/sandboxes/.worktrees"
git -C "$MAIN" worktree remove --force "$WT" 2>/dev/null || true   # clear any stale worktree at this path
git -C "$MAIN" worktree add "$WT" -b "$BRANCH" origin/main
cd "$WT"     # do ALL implementation here; this HEAD is immune to sibling checkouts
```

Why this fixes both failure modes:
- **Fresh base:** `-b "$BRANCH" origin/main` branches off freshly-fetched `origin/main`, so the PR is never "behind main" and never inherits a sibling's in-progress commits.
- **Isolated HEAD:** the worktree's HEAD is independent of the shared checkout, so a sibling switching branches in `~/sandboxes/{repo}` cannot move your HEAD mid-operation — `git-as-agent commit` commits to *your* branch every time.

> The worktree is a clean checkout — regenerate any git-ignored build artifacts the repo needs before building/testing (e.g. a fetched config file), exactly as in a fresh clone.

Implement (Step 4), then commit and push with `-C "$WT"` (or from `cd "$WT"`) so the wrapper acts on the isolated worktree:

```bash
git-as-agent --app <persona> -C "$WT" add <files>
git-as-agent --app <persona> -C "$WT" commit -m "…"      # Refs #{number}; see Step 5
git-as-agent --app <persona> -C "$WT" push -u origin "$BRANCH"
```

`create-pr` (Step 6) and the review loop are unchanged: `create-pr` acts on the **pushed branch** via `--head "$BRANCH"`, so it is location-independent — run it as in Step 6. Keep the worktree for the life of the issue (commit and push review fixes from it the same way). Once the PR is merged or closed, remove it:

```bash
git -C "$MAIN" worktree remove --force "$WT"
```

## Step 4 — Implement the changes

Read the codebase first to understand existing patterns, conventions, and architecture. Use `find`, `grep`, and file reads to orient yourself. Match the style and structure already in use.

**Read and grep source from the worktree (`$WT`), not the shared `~/sandboxes/{repo}` checkout.** The shared checkout can be parked on another agent's (or a stale) branch, so source you read there may predate `origin/main` — and any "fact" you document or cite from it (a function signature, an error path, a constant) can be silently wrong. Your worktree was branched off freshly-fetched `origin/main` in Step 3, so it is the authoritative current source; `cd "$WT"` before grepping, or use `git show origin/main:path/to/file`. This applies especially when verifying a claim about the code (e.g. pushing back on review feedback) — a refuting grep run against a stale tree is worse than no grep.

If the service runs in Docker, **verify the build locally before pushing.** Run `docker build` and `docker run` (or `docker compose up`) and confirm the container starts, passes its healthcheck, and behaves as expected. Don't rely on CI or production to catch container-level issues — a broken build pushed to `main` triggers an immediate production deploy and can cause a crash-loop.

Persona-specific implementation guidance (e.g. the developer's testing rules, the architect's ADR conventions) lives in the persona file or in a persona-specific reference. This workflow does not duplicate it.

## Step 5 — Commit using `git-as-agent`

Always use the `git-as-agent` wrapper for every commit-writing operation. See [`references/agent-github-identity.md`](../../references/agent-github-identity.md) for the wrapper rules.

Reference the issue in commits (`Refs #N`) and reserve closing keywords (`Closes #N`, `Fixes #N`) for the PR body.

For breaking changes, use the `BREAKING CHANGE:` footer or a `!` after the type (e.g. `feat!:`) — `semantic-release` requires a machine-readable token, not prose.

## Step 6 — Push and create a pull request

Use `~/sandboxes/lucos_agent/create-pr` — **never** call `gh-as-agent ... pulls` directly and **never** use `gh pr create`. The `create-pr` script creates the PR and automatically requests lucas42 as a reviewer if the repo is supervised. Combining both steps in one script means the reviewer request cannot be forgotten.

**⚠️ Production dependencies ⚠️ marker (lucas42/lucos#266).** If your change needs a **manual production change** to work — a new credential, config value, service/sidecar, or linked credential that must be set in prod *before or alongside* the deploy — put a section headed **exactly** `⚠️ Production dependencies ⚠️` at the **very top** of the PR body, naming what must be set and by whom (lucas42-only creds especially). **Omit the section entirely when there are none** — no empty boilerplate. Because merge auto-deploys, this marker is what lets the approver confirm the creds are present *before* approving; a change that ships ahead of its creds crash-loops in prod (the 2026-07-09 lucos_locations incident). Keep the body concise so the marker, when present, is impossible to miss. (`create-pr`'s `--body-file` bypasses the GitHub PR template, so this convention — not the template — is what applies to agent-authored PRs.)

**Concise code comments.** Keep in-code comments to one line (two at most, and only for something genuinely non-obvious). Decision rationale — why an approach was chosen, what was ruled out, background context — belongs in the **commit message**, not in code comments or the PR body: it's all in source control, so the commit history is where that narrative lives. Same principle as the concise-PR-body point above.

```bash
BODY_FILE=$(mktemp)
cat > "$BODY_FILE" <<'ENDBODY'
<!-- If this change needs a manual prod change, add a "⚠️ Production dependencies ⚠️" section HERE at the very top; omit if none. -->
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

**Verification (supervised repos only):** After `create-pr` completes, confirm `lucas42` appears in `requested_reviewers` before moving on:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app <persona> \
    repos/lucas42/{repo}/pulls/{number}/requested_reviewers \
    --jq '.users[].login'
# Must print "lucas42". If absent, the PR is not in his review queue.
```

If `lucas42` is missing, request him immediately with `POST /requested_reviewers` before reporting the PR open. A silent miss means the PR waits indefinitely with no one assigned.

**This check works only because it names a human. Never generalise it to "confirm the reviewer is queued"** — App/bot reviewer requests leave no trace at all (see Step 7), so such a check would fail permanently on every `lucos-code-reviewer` PR. `requested_reviewers` is therefore never evidence that the code-reviewer was engaged; the only proof the review loop actually ran is a **submitted review** in `/reviews`. Audit for that instead.

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

**The API call above works for `lucas42` and does NOT work for `lucos-code-reviewer`.** Requesting a bot/App reviewer via `reviewers[]` silently fails: the API returns 200, `requested_reviewers` stays empty, and no `review_requested` event is written to the timeline. There is no error to notice, so a fix pushed after CHANGES_REQUESTED can sit indefinitely believing the reviewer was re-engaged. **`SendMessage` is the only working way to re-request `lucos-code-reviewer`** — send it the PR URL and ask for re-review. Use the API call only when the reviewer to re-request is a human. Do not treat an empty `requested_reviewers` on a bot-reviewed PR as evidence that anyone skipped a step; it is the expected state.

**Never request a reviewer who has not already reviewed the PR.** Specifically: do not request `lucas42` on an unsupervised repo — he was not added at PR creation, so there is nothing to re-engage. Hard-coding `lucas42` in this step pollutes his review queue with PRs he never volunteered to review.

## Step 8 — Comment on unexpected obstacles

If you hit something that might block completion — a dependency issue, an architectural question, a test environment problem — post a comment on the issue immediately. Don't silently work around problems without flagging them.

## Step 9 — Drive the PR review loop

After opening the PR, you are responsible for driving the review loop defined in [`pr-review-loop.md`](../../pr-review-loop.md). Send a message to `lucos-code-reviewer` via **`SendMessage` with `to: "lucos-code-reviewer"`** to request a review, address any feedback, and handle specialist reviews if requested. **Do NOT use the `Agent` tool to spawn a fresh `lucos-code-reviewer` (or any other `lucos-*`) subagent** — they are already teammates on the running team; spawning them via `Agent` bypasses the team flow. See [`references/teammate-communication.md`](../../references/teammate-communication.md) § "Don't spawn teammates as subagents".

**Do not report back** to whoever asked you to do the work until the review loop completes (approval or 5-iteration cap).

**This applies to EVERY PR the issue produces — not just the primary one.** If an issue spans multiple PRs (e.g. a service-code PR *plus* a `lucos_configy` registration PR, or any drive-by doc/convention fix you open during implementation), **each one** follows the same self-driven loop — send a `lucos-code-reviewer` review request for **every** PR before reporting the issue done. A co-primary cross-repo PR (like a configy registration that the issue explicitly requires) is **not** a "minor extra" that can skip the loop, and "I drove the main PR's loop" does not complete the issue while a sibling PR sits unreviewed. Do not ask the coordinator or team-lead to route any of them for you; they are not in the routing path.

**Never merge PRs yourself** — they are merged either automatically (via the auto-merge workflow) or by a human. Just report the approval.

## Step 10 — Verify state before reporting it

Never report PR state (open, merged, awaiting review, approved) from memory. Query the GitHub API for the PR's current state immediately before any status report. Conversation memory drifts within minutes of CI or review activity — stale state is worse than no state.

## Step 11 — If the deliverable is consumed from a local checkout, merging did not ship it

Most lucos repos deploy from `main` automatically, so "merged" and "live" coincide and this step is a no-op. A few do not, and there the merge leaves the deliverable inert with nothing reporting an error: **the agent tooling under `~/sandboxes/lucos_agent`** (scripts other agents invoke by path) and **host-provisioning repos** whose scripts must be run on a machine.

So before reporting done, ask where the change has to be for it to take effect, and check it is there:

- **A local `~/sandboxes` checkout** — confirm the merged content is actually in the working copy, not just on `origin/main`. Compare the file, not the branch name. **Never force it**: these checkouts are shared, and one may sit on another agent's branch or carry uncommitted work. If it is not on a clean `main`, say so in your report and leave it alone rather than switching branches or discarding anything. **One carve-out, and only with all three conditions positively established — not assumed:** the parked branch's HEAD is already an ancestor of `origin/main` (so it is a stale merged branch, not live work), there are no modified tracked files, and you advance with `git merge --ff-only`. That combination cannot discard a commit or an edit, and untracked files survive a branch switch. If you cannot establish all three by checking, report instead. **`~/.claude` is excluded from the carve-out entirely — never run git against that tree.** Its sync is already automated: `scripts/return-to-main.sh`, driven by the post-turn Stop hook, does `git fetch origin main` plus a **mixed** reset to `origin/main` and then `materialize_pr_content`, putting merged PR content on disk within about a minute. Verify the file content on disk and report that; running the carve-out there would be both forbidden and redundant.
- **A production host** — applying it needs root, which per [`references/ssh-production.md`](../../references/ssh-production.md) is structurally a lucas42-only action. Do not attempt it. Report the exact commands so a tracking issue can carry them.

Either way the PR is still complete and the issue still closes on merge — what changes is your report, which must state plainly that the deliverable is not yet live and what remains. A report that says "done" when the running system is unchanged is the failure this step exists to prevent.

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
