---
name: risk-stalled-pr-missing-reviewer-request
description: A supervised-repo PR can be fully green + code-reviewer-approved yet sit unmerged indefinitely if the create-pr reviewer-request step was skipped or bypassed
metadata:
  type: project
---

Found live during 2026-07-31 ops check: lucas42/tfluke#488 (my own PR fixing
GHSA-pm4m-ph32-ghv5, a js-yaml DoS) sat open for 4 days with every required
check green and an APPROVE from `lucos-code-reviewer[bot]`, but never merged.

Root cause: tfluke's configy `unsupervisedAgentCode=false`, so the
`code-reviewer-auto-merge` workflow requires the reviewer to be `lucas42`
specifically — a bot APPROVE doesn't qualify. `requested_reviewers` was
empty, meaning `lucas42` was never added as a reviewer at PR-creation time
(the `create-pr` script normally does this automatically for supervised
repos — see its "Step 2" logic). Whether this PR was opened by-passing
`create-pr`, or `check-unsupervised` mis-fired at creation time, is unverified
— I didn't find conclusive evidence either way.

**Fix applied:** `POST /repos/lucas42/{repo}/pulls/{number}/requested_reviewers`
with `reviewers[]=lucas42`, then verified it stuck.

**Why this matters:** the old "stalled PR" definition in `security-ops-checks.md`
Check 1 only caught PRs stalled by a *failing* check. A PR that's fully green
but missing its reviewer request is invisible to that definition — it just
sits forever with no signal. Updated the instruction (`security-ops-checks.md`)
to add a third stalled-PR criterion: 2+ days open, all checks green, supervised
repo, empty `requested_reviewers`.

**How to apply:** during any future ops check or PR-review-loop work, if a
supervised-repo PR is green + bot-approved but still open after a couple of
days, check `requested_reviewers` before assuming it's just waiting on
lucas42's calendar — it might not be in his queue at all.
