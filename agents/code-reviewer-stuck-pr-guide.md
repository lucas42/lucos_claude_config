# Code Reviewer: Stuck PR Guide

This file is read by `lucos-code-reviewer` during the "review all open PRs" pass.

## Stuck PR Identification Criteria

A PR is stuck if any of the following are true:

**1. CI failure.** Any check-run has `conclusion: failure`, or any commit status has `state: failure`. Check both check-runs AND commit statuses — some CI systems (e.g. CircleCI) report via commit statuses, not check-runs.

**2. `CHANGES_REQUESTED` with no new commits for >24 hours.** Applies to both Dependabot and agent PRs. If no one has pushed a fix within 24 hours of the review, the PR is stuck.

**3. PR on an archived repo.** A PR on an archived repo can never be merged. Action: close the PR with a comment explaining the repo is archived.

**4. Auto-merge enabled but `mergeable_state: blocked` despite passing CI and an existing approval.** This means something is silently preventing the merge — usually a branch protection rule or a required status check that isn't surfacing as a check-run at all (e.g. a stale required check from a deleted workflow). If the required check IS present in `/check-runs` but absent from the rollup, see Criterion 8 instead.

**5. `mergeable_state: dirty` (actual merge conflict) with no rebase for >72 hours.** The PR has genuine conflicts with the base branch. For Dependabot PRs, Dependabot will rebase on its own scheduled cadence — do not immediately escalate. Only flag as stuck if the conflict has been unresolved for >72 hours with no activity. Note: `mergeable_state: behind` (branch is simply behind main, no conflicts) is NOT stuck — GitHub will not block merge for this reason alone, and Dependabot handles it automatically.

**6. Workflow `startup_failure`.** Check recent GitHub Actions workflow runs for the PR's head SHA — not just check-runs. A workflow that fails at startup (e.g. permissions error, missing secret, invalid YAML) won't register as a check-run conclusion at all, so it's invisible to check-run-only queries. Use:
```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  repos/lucas42/{repo}/actions/runs?head_sha={sha}&per_page=10 \
  --jq '.workflow_runs[] | {name, status, conclusion}'
```

**7. Approved + CI green + `mergeable_state: clean` + `auto_merge: null`.** Everything looks ready but auto-merge was never enabled. Check the Actions runs API for the head SHA for any workflow with `startup_failure` or `failure` conclusion — the auto-merge workflow may have failed silently regardless of what it's named. Do NOT rely on checking for a specific workflow filename (e.g. `code-reviewer-auto-merge.yml`) — repos use different names (e.g. `dependabot-auto-merge.yml`).

**8. Rollup-mismatch: `mergeable_state: blocked` + `reviewDecision: APPROVED` + all check-runs passing on the SHA, but a required check is absent from the PR's check-suite rollup.**

*Cause:* Typically occurs after a GitHub Actions outage where the `pull_request` event for a push was dropped. When CodeQL (or another required check) is later triggered manually via `workflow_dispatch`, it creates a check-run on the SHA but doesn't associate it with the PR's check-suite. GitHub's branch protection evaluates the rollup (`statusCheckRollup.contexts`), not the raw `/check-runs` endpoint — so it treats the required check as missing even though it has actually run and passed on the SHA.

*How to distinguish from Criterion 4:* In Criterion 4, the required check doesn't appear in `/check-runs` at all. In this criterion, the check IS present in `/check-runs` with `conclusion: success` — it's simply not wired into the PR's rollup. To confirm: query the commit's check-runs via REST (`/commits/{sha}/check-runs`) to see which checks ran on the SHA, then query the rollup to see what GitHub's branch protection actually evaluates:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer graphql \
  -f query='
    query($repo: String!, $pr: Int!) {
      repository(owner: "lucas42", name: $repo) {
        pullRequest(number: $pr) {
          commits(last: 1) {
            nodes {
              commit {
                statusCheckRollup {
                  contexts(first: 50) {
                    nodes {
                      ... on CheckRun { name status conclusion }
                      ... on StatusContext { context state }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  ' \
  -f repo={repo} \
  -F pr={pr_number} \
  --jq '.data.repository.pullRequest.commits.nodes[0].commit.statusCheckRollup.contexts.nodes[] | {name, status, conclusion, context, state}'
```

A required check present in `/check-runs` with `conclusion: success` but absent from the rollup `contexts` confirms the mismatch.

*Fix:* Close + reopen the PR. The `pull_request:reopened` event triggers a fresh run of required checks (e.g. CodeQL) that get properly associated with the PR's check-suite rollup. Do NOT use `workflow_dispatch` again — that will reproduce the exact same rollup-mismatch.

*Side effects of close+reopen:*
- **Branch deletion race.** If `delete_branch_on_merge` is true for the repo, the branch may be auto-deleted moments after close. The PR cannot be reopened after the branch is deleted (`validation_failed / state cannot be changed`). Reopen must happen within seconds of close — perform close and reopen as a back-to-back sequence without any delay.
- Auto-merge state is dropped on close, but re-set automatically on the next approval review event. This side effect is normally invisible.
- Existing reviews are preserved across close+reopen.

**9. Draft PR parked on a stated pending decision — but the decision has actually landed elsewhere.** A draft PR's body often names a specific venue for an open question ("see issue X unless you say otherwise"). That pointer is written once and can go stale: routing frequently moves *after* the PR body was written, and it can move precisely because the originally-named venue turns out to be one lucas42 never sees (e.g. a Blocked audit-finding, excluded from his triage queue). Checking only the venue the PR body names and finding it "still open" produces a confident but wrong "legitimately parked" verdict — the exact failure mode this audit exists to catch, failing silently and in the dangerous direction (a PR that should be flagged reads as fine).

   Before accepting "parked, not stuck" for any draft whose stated reason is an open question or pending decision:
   - Check the **linked issue** — the one the PR refs/closes, not only the venue named in the PR body — for comments made after the PR/pointer was created.
   - Also check that issue's **reactions**, not just comment text: `repos/lucas42/{repo}/issues/{n}/reactions --jq '.[] | {user: .user.login, content}'`. A `+1` from lucas42 on an issue body or comment is an approval and never appears in the comment-text feed — text-only checks will miss it.
   - Also check that issue's **project-board Status** (see `references/triage-reference-data.md` for the standard GraphQL query pattern). A transition off "Awaiting Decision" is itself evidence the decision landed, even with no textual comment.

   If any of these three show the decision has been made, the PR is **stuck** (the decision exists; the PR just hasn't caught up), not legitimately parked — flag it and route per the table below, even though the PR's own named pointer still reads "open." Confirmed instance: lucos_repos#468 named lucos_loganne#571, which was genuinely still open — but the question had been re-routed to lucas42/lucos_repos#467, where lucas42 had already answered it days earlier.

---

## Stuck PR Escalation Routing

Before escalating, **always try self-service fixes first**. Asking a human to intervene should be a last resort. The most common self-service fix is re-running a failed workflow — ask `lucos-system-administrator` to re-run it (they have `actions:write` access). **Try re-running multiple times before concluding it needs a human** — "unstable status" and "base branch was modified" errors on the Dependabot auto-merge workflow are usually transient and clear on a subsequent re-run. Only escalate to the team lead if the re-run fails repeatedly with the same non-transient error.

| Problem | First action | Escalate to (if first action fails) |
|---|---|---|
| **Test failure in PR code** (tests fail, not infra) | N/A — escalate directly | `lucos-developer` — SendMessage with repo, PR number, failing test |
| **Dependabot lock file sync failure** (`npm ci` / `package-lock.json` mismatch) | Compare PR branch vs main: fetch key dep versions from both lock files. If PR branch resolves any dep to a LOWER version than main, this is a stale-regression PR. **Before closing, check for a recurring pattern:** fetch `repos/lucas42/{repo}/pulls?state=closed&per_page=30&sort=updated&direction=desc` and count Dependabot PRs from the same group/scope closed-without-merge in the past 7 days. EXCLUDE Dependabot self-supersede closes (recognisable by the closing comment "Looks like these dependencies are updatable in another way") — only count closes by agents/humans. If **2+** similar regression-closes are found, do NOT close this PR — close-and-recreate is not solving the underlying problem, and Dependabot will just produce the same regression on its next run. Instead raise an investigation issue on the repo capturing the pattern (PR numbers, dates, the consistent regressing dep) and post a comment on the current PR linking to it; leave the PR open as a live reference for the investigation. Otherwise (0 or 1 prior similar close): close directly with an explanatory comment (DO NOT suggest `@dependabot recreate`). Dependabot is fully deterministic; recreating produces the same result. **Exception — manifest genuinely changed after the PR opened:** before invoking this exception, you MUST verify it explicitly: run `gh-as-agent repos/lucas42/{repo}/commits?path=package.json` and confirm at least one commit's `commit.author.date` is **after** the PR's `created_at`. A lock file that diverges from main is NOT evidence of a manifest change — only a post-PR commit to the manifest counts. If no such commit exists, recreating is deterministic and closing is still correct. | N/A — handle inline (close or raise investigation issue, per the pattern check above). You have `pull_requests: write` and the full context (PR diff, lock file, manifest history, prior closes). Do not escalate to the team lead or to another agent. |
| **CI failure** (infrastructure, runner issues, Docker errors, network timeouts, stale checks, startup failures, persistently red CI) | Ask `lucos-system-administrator` to re-run the failing workflow | `lucos-site-reliability` — SendMessage if re-run fails or problem recurs |
| **Auto-merge workflow failed** (race condition, "unstable status", "base branch modified", startup failure) | Ask `lucos-system-administrator` to re-run — try multiple times; these errors are often transient | Team lead — only if re-run fails repeatedly with the same error and is clearly non-transient |
| **`mergeable_state: dirty`** (genuine merge conflict) | Leave it — Dependabot rebases on its own schedule. Only escalate if still dirty after 72+ hours with no activity | Team lead (for `@dependabot rebase` if you need to force sooner) — **note: `@dependabot rebase` cannot be posted by GitHub Apps; requires lucas42** |
| **Rollup-mismatch** (criterion 8: BLOCKED + APPROVED + check in `/check-runs` but absent from rollup) | Ask `lucos-system-administrator` to close + immediately reopen the PR (back-to-back, no delay — branch deletion race). Provide repo name, PR number, and a note about the branch-deletion risk. | `lucos-site-reliability` — if close+reopen doesn't clear the blockage |
| **`mergeable_state: blocked` with no obvious cause** | `lucos-site-reliability` | SendMessage — likely branch protection issue |
| **Decision already landed elsewhere** (criterion 9: draft's named pointer still open, but linked issue's comments/reactions/Status show the decision was made) | SendMessage the PR author (usually `lucos-developer`/`lucos-architect`/`lucos-ux`) with the repo, PR number, and where the decision actually landed (issue + comment/reaction), so they can push the follow-up commit and mark ready | Team lead — if the author doesn't act within 24h, or the decision's location is itself ambiguous |
| **Auto-merge not triggering** (criterion 7) | Ask `lucos-system-administrator` to re-run the auto-merge workflow | `lucos-site-reliability` — if re-run succeeds but auto-merge still not set |
| **Archived repo** | Close directly | Post a comment explaining why, then close |

---

## Post-escalation Verification

**Treat every escalation as pending until you observe a state change.** Do not report a stuck PR as "handled" just because you sent a message. After escalating:

1. Note the PR as "escalated, pending verification" in your report.
2. On your next PR review pass (or if the teammate messages you back), re-check the PR's state to confirm it has progressed.
3. If the PR is still stuck after the teammate's action, re-escalate with the new information.

**`@dependabot` commands cannot be posted by GitHub Apps** — Dependabot responds "Sorry, only users with push access can use that command." This applies to both `@dependabot recreate` and `@dependabot rebase`. When a recreate or rebase is warranted, **close the PR directly** — Dependabot will open a fresh PR. Closing is equivalent to recreate and works without push-user access. (Confirmed: lucos_arachne #685, 2026-06-26.)
