# Workflow: review PR

This workflow is triggered when the dispatcher (team-lead) sends one of:

- `"review PR {url}"` — review a specific pull request.
- `"review any open PRs"` — discover and review every open PR across the estate.

It is owned by `lucos-code-reviewer`. Read this file in full at the start of every invocation. Do not work from memory of previous runs — the steps may have changed.

## Discovery: "review any open PRs"

If no specific PR was named, run the discovery script first:

```bash
~/sandboxes/lucos_agent/get-prs-for-review
```

This returns every open PR across unarchived `lucas42` repos. Review **every** PR returned, one at a time, applying the full per-PR procedure below. If the script returns no results, send a `SendMessage` to `team-lead` reporting that discovery found no open PRs, then stop. (See Step 8 for the completion-report format.)

## Step 1 — Check for existing reviews

Before reviewing, always check the PR's existing reviews via the API:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  repos/lucas42/{repo}/pulls/{pr_number}/reviews
```

If `lucos-code-reviewer[bot]` has already submitted a review on the current HEAD commit (compare the review's `commit_id` against the PR's `head.sha`), and no new commits/comments/activity have occurred since, **skip the PR** — note it as "skipped (already reviewed on current HEAD)" in your Step 8 completion SendMessage to `team-lead`.

Do not rely on memory of prior reviews — each agent invocation starts fresh.

## Step 2 — Gather context

- Fetch the PR details: title, description, author, base branch, head branch, list of changed files.
- Identify linked issues in the PR body (`Closes #N`, `Fixes #N`, `Resolves #N`) and fetch them to understand the problem being solved. **If the PR clearly completes an issue but the body only uses `Refs #N`, request the change** — the body should use a closing keyword so the issue is auto-closed on merge.
- Fetch the full diff and examine every changed file.
- If the repo has a `CLAUDE.md` or `README`, consult it for project conventions.

All GitHub interactions go through `gh-as-agent --app lucos-code-reviewer`.

## Step 3 — Evaluate the PR

Systematically evaluate the PR against the **Quality Checks** and **Red Flags** in your persona file's "Review Heuristics" section. They are loaded into your system prompt at all times — do not duplicate them here.

## Step 4 — Form your verdict

- **APPROVE** — all quality checks pass, no red flags.
- **REQUEST_CHANGES** — one or more red flags, or a quality-check gap that should block merge.
- **REQUEST SPECIALIST REVIEW** — domain expertise needed:
  - `lucos-security` for authentication, authorization, credentials, cryptography, input sanitization, or new attack surface.
  - `lucos-site-reliability` for deployment config, monitoring, alerting, health checks, backups, failover, migrations, or significant operational risk.
  - You may still note non-specialist issues — specialist review supplements your own, it doesn't replace it.

If you spot a concrete, fixable issue, **request changes** — even if the fix is minor. A note in an approval is easy to miss and may never get fixed. Reserve approvals-with-notes for genuinely subjective observations or things requiring significant design discussion. Do not bury actionable feedback as a parenthetical in an approval.

## Step 5 — Post the review

Always use `gh-as-agent --app lucos-code-reviewer`. Never `gh api` directly, never `gh pr review` — those would post under the wrong identity. Always wrap `body` in a `<<'ENDBODY'` heredoc; inline `-f body="..."` breaks newlines and backticks. See [`references/agent-github-identity.md`](../../references/agent-github-identity.md) for the heredoc pattern and the `{owner}/{repo}` template-substitution gotcha.

### Approve

Single encouraging, specific sentence relevant to the actual change (not generic "looks good"). If appropriate, add a fun reptile fact (see your persona file's Character section for when this is appropriate and how to track previously-used reptiles).

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  repos/lucas42/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  -f event="APPROVE" \
  --field body="$(cat <<'ENDBODY'
Your encouraging comment and (if appropriate) reptile fact here.
ENDBODY
)"
```

### Request changes

List **all** problems found, grouped logically. Explain *why* each issue matters. Constructive, respectful, with markdown formatting.

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  repos/lucas42/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  -f event="REQUEST_CHANGES" \
  --field body="$(cat <<'ENDBODY'
Your detailed markdown comment with all issues found.
ENDBODY
)"
```

### Request specialist review

Three actions, all required:

1. **Post a `COMMENT` review** (not `APPROVE`/`REQUEST_CHANGES`, so you don't block the PR yourself). Explain what specialist input you're requesting and why; include any non-specialist issues you found so the specialist sees them.
2. **`SendMessage` the specialist** with repo, PR number, PR URL, and a summary of what to weigh in on. Ask them to message you back when done so you can complete your final review.
3. **Output a signal line** on its own line, exactly:
   ```
   SPECIALIST_REVIEW_REQUESTED: <persona-name>
   ```
   e.g. `SPECIALIST_REVIEW_REQUESTED: lucos-security`. The signal is for the dispatcher only — the specialist will never see it, so step 2 is mandatory.

After the specialist responds, you will be re-dispatched. Read the specialist's PR comments and factor them into your final verdict — then APPROVE or REQUEST_CHANGES.

**When relaying a third-party sign-off in a completion report, cite the GitHub artifact.** A SendMessage confirmation is not a sign-off — it isn't visible to the user, isn't in the PR history, and isn't auditable after the session ends. If you have a SendMessage confirmation but no GitHub artifact, your report must say so explicitly: *"security confirmed via SendMessage but has not yet posted on the PR — chasing them for a visible review."* The source of truth for PR review state is the GitHub API, not conversation history.

## Step 6 — Check CI status and follow up

After posting your review:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  repos/lucas42/{repo}/commits/{head_sha}/check-runs --jq '.check_runs[] | {name, status, conclusion}'
```

- **CI not finished** (any check `in_progress` or `queued`): poll every 60 seconds, up to 10 minutes. After that, move on.
- **CI passes:** nothing more needed.
- **CI fails:** post a follow-up `REQUEST_CHANGES` review flagging the specific failures.
- **No check runs at all:** nothing more needed.

**Why post the code review before waiting for CI:** waiting first creates a race — if the developer pushes a new commit, your review ends up against a SHA whose diff you never read. Post review first, then handle CI separately.

## Step 7 — Improvements spotted during review

You may notice things beyond immediate correctness — adjacent improvements, polish, patterns to standardise.

- **Default: `REQUEST_CHANGES`.** If concrete and fixable by the author without outside input, block the PR on it. Request changes rather than tucking it into an approval or raising a separate issue. It's much easier to address at the point it arises than to triage later.
- **Only raise a separate issue** when the improvement genuinely needs outside input — architectural design, lucas42 sign-off, multi-repo work. In those cases, raise the issue and mention it briefly in your review comment. Never raise a separate issue for something fixable in the current PR.
- Don't block on trivial style nits or personal preferences.
- **Never flag a factual nit without verifying the claim from the source.** Memory for things like teammate colour assignments is unreliable — read the relevant `~/.claude/agents/{persona}.md` frontmatter before commenting on it.

## Step 8 — Completion report (mandatory)

**Before going idle, send a `SendMessage` to `team-lead`.** This is required at the end of every invocation — whether you reviewed PRs, skipped them, found none, or are waiting for a specialist. Never go idle without it.

The message must cover, briefly:

- **Discovery result:** what `get-prs-for-review` returned, or the specific PR URL for a `review PR {url}` trigger.
- **Outcome per PR:** approved / changes requested / specialist consulted / skipped (already reviewed on current HEAD) / none found.
- **Auto-merge status** for any PR you approved: whether `auto_merge` is non-null (enabled) or null (awaiting lucas42 approval, or stuck).
- **Stuck-PR escalations:** any stuck PRs found, the category, and the action taken. Omit if none.

Keep it brief — a few lines is enough. The team-lead uses this to decide whether to proceed to triage or wait.

**Specialist-referral case:** if you are mid-review and waiting for a specialist to respond (i.e. you sent `SPECIALIST_REVIEW_REQUESTED`), still send a completion SendMessage noting that you are awaiting the specialist's response and will post a final verdict when re-dispatched. Do not go idle silently.

## Two auto-merge workflows — do not conflate

- **`dependabot-auto-merge.yml`** — merges Dependabot PRs. Does **not** check `unsupervisedAgentCode`. Dependabot PRs auto-merge on any repo that has this workflow.
- **`code-reviewer-auto-merge.yml`** — merges PRs approved by `lucos-code-reviewer[bot]`. **Does** check `unsupervisedAgentCode` — on supervised repos, bot approval alone won't trigger merge.

The `unsupervisedAgentCode` flag is irrelevant to Dependabot PRs. If an approved Dependabot PR isn't merging, investigate the dependabot-auto-merge workflow (startup failure, missing file, etc.) — do not attribute it to the supervised flag.

## Supervision status — verify before claiming

Before stating a repo's supervision status (e.g. "this needs lucas42's approval", "auto-merge will fire", "supervised", "unsupervised"), run:

```bash
~/sandboxes/lucos_agent/check-unsupervised <repo>
```

Exit 0 = unsupervised (auto-merge fires on bot approval); exit 1 = supervised (needs human approval); exit 2 = error. Base the claim on the exit code. Do not infer from repo name, conversational recall, or proximity to similar-looking repos.

**Do NOT use `curl -sf "https://configy.l42.eu/repositories/{repo}" | jq '.unsupervisedAgentCode'`** — repos not in configy (e.g. `lucos`, `lucos_backups`) return empty output, which silently misclassifies them as supervised.

## Post-approval verification

After approving any PR, run these checks before moving on:

1. **Check CI status.** Never approve a PR with failing CI — verify check-runs AND commit statuses (some CI systems like CircleCI report via commit statuses, not check-runs) before posting `APPROVE`. If CI is failing, post `REQUEST_CHANGES` instead, regardless of code quality.
2. **Check auto-merge.** Wait ~30 seconds after approval, then re-fetch the PR and check the `auto_merge` field.
   - **Non-null:** auto-merge enabled, will merge when CI passes. Report as "auto-merge enabled".
   - **Null:** check supervision status with `check-unsupervised` (above). If supervised (exit 1), this is **expected** — report as "awaiting lucas42 approval", not "auto-merge triggered". If unsupervised (exit 0) and `auto_merge` is still null, flag as stuck (criterion 7 in the stuck-PR guide) and check the Actions runs API for any workflow with `startup_failure` or `failure`.
   - **Never report "auto-merge triggered" or "auto-merge succeeded" based solely on the workflow check-run having `conclusion: success`.** A succeeded workflow on a supervised repo means it ran and correctly did nothing. The only reliable signal is `auto_merge` being non-null on the PR itself.

## Stuck PR audit (during "review any open PRs")

As part of every "review any open PRs" pass, audit each open PR for signs it is stuck — cannot make progress without intervention, and no one is actively working on it. Read [`agents/code-reviewer-stuck-pr-guide.md`](../code-reviewer-stuck-pr-guide.md) for the full criteria (7 types), escalation routing table, and post-escalation verification protocol.

When reporting results, include a separate **"Stuck PRs"** section listing any stuck PRs found, the category of stuckness, and the action taken (escalated to whom, or closed). If no stuck PRs were found, omit the section.

## What you don't do

- **Don't approve your own PRs.** Create the PR, let the review process handle it.
- **Don't merge PRs yourself.** Auto-merge or a human handles it; report the approval and stop.
- **Don't touch labels.** See [`references/label-workflow.md`](../../references/label-workflow.md).
- **Don't pick up another PR in the same session** unless explicitly dispatched. Report when the assigned PR is done; the dispatcher decides what's next.
