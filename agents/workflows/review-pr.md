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

    **No size or triviality exception.** "Regardless of what the change touches" includes a one-line docs edit, a status-flip, a typo fix — anything, no matter how small or how confident you are it's safe. Do not let your own judgment that a change is "obviously trivial" substitute for the sign-off; that judgment is exactly what this rule removes discretion over. Request `lucos-security` *before* posting `APPROVE`, every time, on every PR in these repos. (Confirmed miss: lucos_creds#461, a one-word ADR status flip, approved without requesting sign-off first — caught and corrected same-session, 2026-07-12.)

    - **`lucos_firewall`** — the estate's network-perimeter enforcement (ADR-0007); a bug there can lock the whole estate out or silently open it up.
    - **`lucos_creds`** — the estate's credential/secret store and the source of every inter-service auth key (`CLIENT_KEYS`, scopes, TSIG secrets); a bug there can leak secrets or broaden access across every service that authenticates against it.
    - **`lucos_aithne`** — the estate's authentication/identity service (ADR-0001): credential store, session-token spine, OIDC/OAuth2 endpoints, scope-grant authority. Any change is security-relevant by definition; lucas42 confirmed (2026-06-10) that *every* aithne PR requires `lucos-security` review — do not fall back to change-nature judgment (a non-auth-looking change like an `/_info` fix still requires it).
    - **`lucos_aithne_jsclient`** — the shared JS library (lucos_aithne_jsclient ADR-0001, 2026-07-10) that will hold the estate's single JWT-verification implementation, consumed by `lucos_creds`, `lucos_notes`, `lucos_media_seinn`, `lucos_loganne`, and future JS services behind aithne. It's a client library rather than the auth service itself, but a defect here has the same estate-wide blast radius as one in `lucos_aithne` — every consumer inherits it on the next version bump. Added when the founding ADR (docs-only) still warranted a security specialist request via the change-nature trigger; added here directly so future *code* PRs in this repo don't have to re-derive that judgment each time.

    To add another repo to this always-review list, append it here rather than duplicating the rule.

    **Do not add auth-*consumer* services to this list (e.g. `lucos_eolas`, `lucos_contacts`).** The list is only the core auth/perimeter/secret infrastructure above. For consumer services, you judge per-PR security relevance via the Step 4 change-nature triggers — requesting `lucos-security` on a specific consumer PR is correct; a blanket repo-level mandate is not.

    **Always-review does NOT mean supervised.** These are orthogonal properties. `lucos_aithne` is on the always-review list (security sign-off required on every PR) *and* unsupervised (bot approval auto-merges; lucas42 is not required). Never read "this repo requires security review" as "this repo needs lucas42's approval to merge". Always run `check-unsupervised` independently to determine merge-gating — do not infer it from the always-review classification.

    **Exception — `lucos-security`-authored PRs (self-approval is structurally impossible).** When `lucos-security` is the *author* of the PR, GitHub will not accept a formal approving review from them on their own PR. In that case, an explicit, unambiguous **approving comment** from `lucos-security` on the PR — a clear "good to merge / security sign-off", not merely a neutral or descriptive remark — satisfies the security sign-off requirement. Treat it as the go-ahead and `APPROVE`. This applies *only* when security is the PR author and the formal approval is structurally blocked; for every other author, a formal `lucos-security` review/approval is still required. (Confirmed by lucas42, 2026-06-12, resolving the lucos_aithne#98 deadlock.)

**Production-dependency check (lucos#266 Option A).** If a PR body has a `⚠️ Production dependencies ⚠️` section (the org PR template prompts human authors for this; agent authors add it per `implement-issue.md` Step 6), do **not** `APPROVE` until you've confirmed the named prod creds/config are actually present in the target environment — on unsupervised repos your approval auto-merges straight into an auto-deploy, so you are the gate; on supervised repos lucas42's approval is the gate and does the same check, but still verify the marker is present and accurate before you approve. A required-but-missing prod dependency is `REQUEST_CHANGES` (or hold) until it's set — a cred-gated change that merges ahead of its creds crash-loops in prod. (Root cause of the 2026-07-09 `lucos_locations` incident, lucos#265.)

**Migration-coupled-deploy check (lucos_claude_config#121).** Because deploy follows merge automatically, a PR that carries a **breaking on-disk migration the newly-deployed image cannot perform for itself** — it needs out-of-band operator material before it can serve (a fresh secret, a value the running image can't derive) — is dangerous to approve blind: the new image crash-loops until the one-time manual step runs. (This caused the ~46-minute estate-wide auth outage on 2026-06-30 — the aithne KEK-derivation change served before anything migrated the keys; `lucos` `docs/incidents/2026-06-30-aithne-kek-migration-deploy-race.md`.) The judgement "is this PR migration-coupled?" is yours. When you judge that it is, do **not** `APPROVE` until **both** gates are satisfied, otherwise `REQUEST_CHANGES` / hold:

  1. the migration has been **rehearsed end-to-end in `development` first** (agents have full dev permissions — there's no reason not to), and
  2. **every manual step has a named owner who has confirmed they are ready** — that readiness must exist *before* merge, since merge auto-deploys.

  Prefer steering the author away from the manual step entirely: a migration designed self-contained / dual-read (the new image migrates data forward at startup with zero operator action, as aithne's `MigrateSigningKeyEncryption` does), or one that decouples a *value rotation* from a *format/derivation change* (ship the self-migrating format change first, rotate the value online afterwards), triggers **neither** gate. This is a lightweight checklist prompt, not new machinery — the convention is captured in lucos_claude_config#121, there is no separate ADR.

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

  **Stale-green main + PR diff cannot cause the failures** (e.g. the PR only changes workflow YAMLs but CircleCI Python tests are failing): do **not** frame this as a main regression. Check when main's CI last ran — if main's last run predates a recent external package release, the failures are likely caused by an **unpinned breaking dependency**, not broken committed code. Signature: green-but-stale main + shared lucos package just released a semver-major. Also check estate-wide scope — other repos that share the same unpinned dep will fail identically. Frame the root cause as a dependency issue, not a codebase regression, and do not tell the developer "fix main."

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

**Re-fetch every PR's state immediately before writing the completion report — and before any mid-session SendMessage that references a PR's state for any reason.** This rule applies to every PR named in the message regardless of *why* you're naming it: merge/approval status, action items ("this PR should be closed"), predecessor/related PRs, stuck escalations, or anything else. Do not rely on state from earlier in the session — a PR reviewed or mentioned an hour ago may already have merged or closed. For each PR in the report, call `gh-as-agent repos/lucas42/{repo}/pulls/{number} --jq '{state, merged_at, merged}'` and use the live values before asserting anything about it. Describing a merged PR as "awaiting approval", "still open", or "should be closed" is actively misleading. (Confirmed failures: PR #6 stuck claim after merge at 23:03Z; PR #311 "still open / should be closed" when it had merged at 19:14Z earlier the same session.)

The message must cover, briefly:

- **Discovery result:** what `get-prs-for-review` returned, or the specific PR URL for a `review PR {url}` trigger.
- **Outcome per PR:** approved / changes requested / specialist consulted / skipped (already reviewed on current HEAD) / none found.
- **Auto-merge status** for any PR you approved: whether `auto_merge` is non-null (the auto-merge workflow has fired) or null (the gating approval hasn't landed yet — on a supervised repo that means awaiting lucas42, which is the normal healthy state and **not** evidence of stuck-ness).
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

**Invocation gotcha:** run `check-unsupervised` as a standalone command — never prepend `gh-as-agent` to it. `~/sandboxes/lucos_agent/gh-as-agent ~/sandboxes/lucos_agent/check-unsupervised {repo}` passes the script path as an API argument to `gh-as-agent`, returns exit 1, and silently misclassifies an unsupervised repo as supervised. (Confirmed: lucos_aithne#229.)

**Always-review does NOT imply supervised.** These two classifications are independent. A repo on the always-review list (e.g. `lucos_aithne`) still requires a `check-unsupervised` run to determine merge-gating — never skip it because the repo is security-gated. `lucos_aithne` is always-review *and* unsupervised: bot approval auto-merges after the security pass; lucas42 is not required.

**Do NOT use `curl -sf "https://configy.l42.eu/repositories/{repo}" | jq '.unsupervisedAgentCode'`** — repos not in configy (e.g. `lucos`, `lucos_backups`) return empty output, which silently misclassifies them as supervised.

## Post-approval verification

After approving any PR, run these checks before moving on:

1. **Check CI status.** Never approve a PR with failing CI — verify check-runs AND commit statuses (some CI systems like CircleCI report via commit statuses, not check-runs) before posting `APPROVE`. If CI is failing, post `REQUEST_CHANGES` instead, regardless of code quality.

   **Re-fetch the PR head SHA immediately before posting *any* review** (`APPROVE`, `REQUEST_CHANGES`, or `COMMENT`) — if the head has changed since you fetched the diff, your analysis is stale and your review will be posted against a commit you haven't examined. GitHub attaches reviews to the *current* PR head, not the commit you reviewed. A review posted on an unexamined commit is worse than no review. (Failure modes: lucos_contacts PR #715 — a revert commit landed during CI wait; APPROVE posted on reverted code. lucos_creds PR #366 — PR force-pushed from restriction to deletion approach between diff-fetch and COMMENT post; stale "fresh key pair + restrict-environment" analysis published on the deletion commit.)
2. **Check auto-merge.** Wait ~30 seconds after approval, then re-fetch the PR — fetch `{state, merged_at, auto_merge}`.
   - **`state: closed` / `merged_at` non-null:** PR already merged (directly, without queuing). Report as "merged". Stop here — do not interpret `auto_merge`.
   - **`auto_merge` non-null:** queued auto-merge enabled. Before reporting "will merge automatically / will merge once X passes", verify two things: (a) fetch `mergeable_state` from the PR object and confirm it is NOT `blocked`; (b) fetch `commits/{sha}/check-runs` AND `commits/{sha}/statuses` and confirm no required check has `conclusion: failure` or `state: failure`. If `mergeable_state: blocked` or any required check is failing, report as "blocked on {check-name}" — not as imminent. The trap: after approving a PR, you may re-trigger CI on one check and attribute the pending state to that re-triggered check, while missing a different required check that was already failing — your own earlier escalation, even. The fetch takes 5 seconds and is the only way to catch it. (Confirmed failure: lucos_repos #432 — reported "auto-merge queued, waiting for CodeQL" when `ci/circleci: lucos/build` was already `failure` on the same SHA.)
   - **`auto_merge` null, PR still open:** run `check-unsupervised` **now** — do not skip this step or infer supervision from repo name or memory.
     - **Supervised (exit 1):** expected — report as "awaiting lucas42 approval". The workflow will call `gh pr merge --auto --merge` automatically once he approves; he does NOT need to click Merge.
     - **Unsupervised (exit 0):** the `code-reviewer-auto-merge.yml` workflow may still be in flight (merges synchronously when CI is already green — which means the PR may merge without ever setting `auto_merge`). Check the Actions runs API for the auto-merge workflow run status. If the workflow is still `in_progress`, wait for it to complete then re-fetch. If the workflow completed `success` and the PR then merged, report as "merged". If the workflow completed `success` but the PR is still open with `auto_merge: null`, flag as stuck (criterion 7) and investigate.
   - **Important:** `auto_merge: null` does NOT indicate supervision. On unsupervised repos, `code-reviewer-auto-merge.yml` merges directly (sometimes synchronously, without ever setting the GitHub native `auto_merge` toggle). Never report "awaiting lucas42" based on `auto_merge: null` alone — always run `check-unsupervised` first. (Confirmed failure: lucos PR #238 — reported "awaiting lucas42 (supervised)" when `lucos` is unsupervised; PR merged 1 second later on bot approval.)
   - **Never report "auto-merge triggered" or "auto-merge succeeded" based solely on the workflow check-run having `conclusion: success`.** A succeeded workflow on a supervised repo means it ran and correctly did nothing.
   - **If the PR has merged and you need to characterise what triggered it** (e.g. "merged on bot approval" vs "merged on lucas42's approval"), fetch the reviews list — `repos/lucas42/{repo}/pulls/{n}/reviews --jq '.[] | {state, submitted_at, user: .user.login}'` — and compare approver timestamps against `merged_at`. The merge trigger is the approval that immediately precedes `merged_at`, not the earliest approval in the list. A small gap (seconds to minutes) between bot approval and merge does NOT imply the bot triggered it — lucas42 may have approved in between. Never assert a supervision gap without this check.

## Stuck PR audit (during "review any open PRs")

As part of every "review any open PRs" pass, audit each open PR for signs it is stuck — cannot make progress without intervention, and no one is actively working on it. Read [`agents/code-reviewer-stuck-pr-guide.md`](../code-reviewer-stuck-pr-guide.md) for the full criteria (7 types), escalation routing table, and post-escalation verification protocol.

When reporting results, include a separate **"Stuck PRs"** section listing any stuck PRs found, the category of stuckness, and the action taken (escalated to whom, or closed). If no stuck PRs were found, omit the section.

## What you don't do

- **Don't approve your own PRs.** Create the PR, let the review process handle it.
- **Don't merge PRs yourself.** Auto-merge or a human handles it; report the approval and stop.
- **Don't touch labels.** See [`references/label-workflow.md`](../../references/label-workflow.md).
- **Don't pick up another PR in the same session** unless explicitly dispatched. Report when the assigned PR is done; the dispatcher decides what's next.
