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

  **Mandatory security sign-off — always-review repos (repo-scoped, always):** *every* PR on a repository in the list below requires `lucos-security` review, regardless of what the change touches — any change to these is security-relevant by definition. On any PR in one of these repos you **must** request `lucos-security` review (follow "Request specialist review" below) and you **must not `APPROVE` until `lucos-security` has posted a go-ahead on the PR itself** (a GitHub review/comment, not a SendMessage — see the GitHub-artifact rule below). This is in addition to the change-nature triggers above.

    - **`lucos_firewall`** — the estate's network-perimeter enforcement (ADR-0007); a bug there can lock the whole estate out or silently open it up.
    - **`lucos_creds`** — the estate's credential/secret store and the source of every inter-service auth key (`CLIENT_KEYS`, scopes, TSIG secrets); a bug there can leak secrets or broaden access across every service that authenticates against it.

    To add another repo to this always-review list, append it here rather than duplicating the rule.

If you spot a concrete, fixable issue, **request changes** — even if the fix is minor. A note in an approval is easy to miss and may never get fixed. Reserve approvals-with-notes for genuinely subjective observations or things requiring significant design discussion. Do not bury actionable feedback as a parenthetical in an approval.

**"Unlikely in practice" is not a valid qualifier.** Probability of the failure scenario is not grounds for downgrading a concrete correctness or robustness gap to a non-blocking note. If the fix is one line and the gap is real — exception-path resource leak, partial cleanup on error, missing guard — request changes. The cost of a follow-up issue exceeds the cost of blocking the PR. (Confirmed: lucos_backups #292 — `closeConnection()` skipped `gateway.close()` if `connection.close()` raised; approved with a note; became a separate PR #293.)

**Supervision status does not affect this rule.** "The repo is supervised so lucas42 will see the note anyway" is not a valid reason to approve with notes instead of requesting changes. The rule is about signal strength, not merge safety.

## Step 5 — Post the review

Always use `gh-as-agent --app lucos-code-reviewer`. Never `gh api` directly, never `gh pr review` — those would post under the wrong identity.

**Always use the file-backed body pattern for review bodies.** Code reviews routinely discuss code containing `{repo}`, `{owner}`, `{sha}`, and other `{...}` placeholder patterns — `gh api` performs template substitution on these inside `--field body="..."` even when the shell doesn't, silently corrupting the posted text. Writing the body to a temp file and passing `--field body=@$BODY_FILE` bypasses this entirely. See [`references/agent-github-identity.md`](../../references/agent-github-identity.md) for the full gotcha explanation.

### Approve

Single encouraging, specific sentence relevant to the actual change (not generic "looks good").

```bash
BODY_FILE=$(mktemp)
cat > "$BODY_FILE" <<'ENDBODY'
Your encouraging comment here.
ENDBODY
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  repos/lucas42/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  -f event="APPROVE" \
  --field "body=@$BODY_FILE"
rm "$BODY_FILE"
```

### Request changes

List **all** problems found, grouped logically. Explain *why* each issue matters. Constructive, respectful, with markdown formatting.

```bash
BODY_FILE=$(mktemp)
cat > "$BODY_FILE" <<'ENDBODY'
Your detailed markdown comment with all issues found.
ENDBODY
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  repos/lucas42/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  -f event="REQUEST_CHANGES" \
  --field "body=@$BODY_FILE"
rm "$BODY_FILE"
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

After posting your review, check **both** endpoints — CircleCI publishes via commit statuses, not check-runs; checking only check-runs misses it:

```bash
# GitHub Actions, CodeQL, convention checks
# IMPORTANT: use .head_sha directly from the check-run object — do NOT alias it from
# .pull_requests[0].head.sha, which is null when there is no PR cross-reference and will
# make a real failure look like an orphaned/stale check-run.
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  repos/lucas42/{repo}/commits/{head_sha}/check-runs --jq '.check_runs[] | {id, name, status, conclusion, head_sha}'

# CircleCI and other status-based CI
# IMPORTANT: the statuses endpoint returns ALL historical entries (newest-first).
# Use unique_by(.context) to keep only the latest state per context.
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  repos/lucas42/{repo}/commits/{head_sha}/statuses \
  --jq 'unique_by(.context) | .[] | {context, state, description}'
```

A PR with all check-runs green but a failing CircleCI status will show `mergeable_state: blocked` with no obvious cause — this is the most common reason for that symptom.

The combined state is CI-passing only when **all** check-runs have `conclusion: success` **and** all latest-per-context commit statuses have `state: success` (or there are none).

**Do not use an `until` loop that checks for any pending entry in the raw statuses list** — old superseded entries remain in the list forever and the loop will never exit. Instead, re-fetch with `unique_by(.context)` and check whether any latest-per-context entry has `state: pending`.

- **CI not finished** (any check `in_progress` / `queued`, or any latest-per-context status `pending`): poll every 60 seconds, up to 10 minutes. After that, move on.
- **CI passes:** nothing more needed.
- **CI fails:** Read the job logs **before** characterising the failure in your review — fetch the job ID via `repos/{repo}/actions/runs?head_sha={sha}` then `repos/{repo}/actions/jobs/{job_id}/logs`, or the CircleCI URL from the `target_url` field on the failing status. Do **not** call the failure "transient" or "likely flaky" without evidence from the logs. A documentation-only PR with a failing test job is still failing — check whether the failure pre-exists on `main` (fetch `repos/{repo}/commits/{main_sha}/statuses`) before speculating. Then post a `REQUEST_CHANGES` review flagging the specific failure with whatever diagnosis you found.

  **After a CI-failure REQUEST_CHANGES, if CI later clears:** post a fresh `APPROVE` review immediately — do not just report "CI green" without updating your formal review state. GitHub's effective review state is your *latest* review; a REQUEST_CHANGES that is never superseded by an APPROVE blocks the PR even after the problem is resolved. The re-approve body should note that it supersedes the earlier REQUEST_CHANGES and confirm CI is now green.
- **No check runs and no statuses:** nothing more needed.
- **Check-runs absent despite required checks in branch protection:** if all CircleCI statuses pass but GitHub Actions check-runs never appear (total_count=0 after several minutes), fetch the branch protection required checks (`repos/{repo}/branches/main`), identify which required checks are missing, and treat this as an infrastructure failure — post the code-quality APPROVE (or REQUEST_CHANGES) based on what you have, note in the review that `{CheckName}` hasn't triggered and may block auto-merge, then `SendMessage lucos-site-reliability` with the two affected PR URLs, head SHAs, and the specific missing check name. Do **not** hold the review waiting indefinitely for a check that may never fire.

**Why post the code review before waiting for CI:** waiting first creates a race — if the developer pushes a new commit, your review ends up against a SHA whose diff you never read. Post review first, then handle CI separately.

## Step 7 — Improvements spotted during review

You may notice things beyond immediate correctness — adjacent improvements, polish, patterns to standardise.

- **Default: `REQUEST_CHANGES`.** If concrete and fixable by the author without outside input, block the PR on it. Request changes rather than tucking it into an approval or raising a separate issue. It's much easier to address at the point it arises than to triage later.
- **Only raise a separate issue** when the improvement genuinely needs outside input — architectural design, lucas42 sign-off, multi-repo work. In those cases, raise the issue and mention it briefly in your review comment. Never raise a separate issue for something fixable in the current PR.
- Don't block on trivial style nits or personal preferences.
- **Never flag a factual nit without verifying the claim from the source.** Memory for things like teammate colour assignments is unreliable — read the relevant `~/.claude/agents/{persona}.md` frontmatter before commenting on it.

## Step 8 — Completion report (mandatory)

**Before going idle, send a `SendMessage` to `team-lead`.** This is required at the end of every invocation — whether you reviewed PRs, skipped them, found none, or are waiting for a specialist. Never go idle without it.

**PR URLs in completion reports must be derived from the API, not typed from memory.** Use the `html_url` field from the PR object you already fetched, or construct it as `https://github.com/lucas42/{repo}/pull/{number}` using the exact repo name you queried — never recall it from context. Repo names are easy to mis-type (e.g. `lucos` vs `lucos_loganne`), and wrong URLs in completion reports waste the reader's time.

**Re-fetch every PR's state immediately before writing the completion report.** Do not rely on state from earlier in the session — a PR reviewed an hour ago may already have been merged (especially on fast-moving sessions with multiple PRs). For each PR in the report, call `gh-as-agent repos/lucas42/{repo}/pulls/{number} --jq '{state, merged_at, auto_merge}'` and use the live values. Describing a merged PR as "awaiting approval" is actively misleading to the team-lead.

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

   **Re-fetch the PR head SHA immediately before posting `APPROVE`** — if the head has changed since you verified the diff (e.g. a new commit was pushed while CI was running), inspect the new diff before approving. GitHub attaches reviews to the *current* PR head, not the commit you reviewed. A review posted on an unexamined commit is worse than no review. (Failure mode: lucos_contacts PR #715 — a revert commit landed during CI wait; APPROVE was inadvertently posted on the reverted code.)
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
