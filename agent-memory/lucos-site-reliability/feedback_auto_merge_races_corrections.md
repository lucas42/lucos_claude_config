---
name: auto-merge-races-corrections
description: If pushing a correction commit to an already-approved PR, mark the PR as draft first (or dismiss the existing review). Auto-merge fires on the recorded approval, not the latest commit, and can win the race against your push.
metadata:
  type: feedback
---

GitHub's auto-merge fires when the approval status of a PR is satisfied — it doesn't re-validate when new commits are pushed (unless the repo has "require re-approval after changes" turned on, which most lucos repos don't). So if you push a substantive correction commit to a PR that's already been approved, the merge can fire on the *prior* approval before the new commit gets re-reviewed.

**Why:** On 2026-05-22, code-reviewer approved `lucas42/lucos#189` (incident-report amendment, first commit `7b57e40`). Auto-merge fired. Meanwhile, architect's review surfaced a load-bearing factual error in that commit. I pushed a corrections commit (`4821352`) and SendMessaged code-reviewer to re-review. By the time the SendMessage landed, the PR had already auto-merged at `7b57e40` — the corrections commit was on the branch but not on main. Required a follow-up PR (`#190`) to apply the same change-set on top of merged main. The first-commit content (with the factual error) is permanently in git history; the corrections only land on top of it via the follow-up.

**How to apply:**

When you receive substantive feedback after a PR has been approved but before it has merged:

1. **Mark the PR as draft** (`gh pr ready --undo` or the GitHub UI). Auto-merge pulls back from draft PRs.
2. *Then* push the correction commit.
3. Mark the PR as ready-for-review again.
4. Re-request review.

Alternative: dismiss the existing review explicitly before pushing.

Either pattern is safer than push-then-message, because the push-then-message order races against the merge.

For the lucos repos specifically: code-reviewer's turnaround is fast, often under a minute. The race window after an approval is therefore short — assume zero, not "I have time to push first and notify second".

The escape hatch when this *has* bitten: open a follow-up PR on top of merged main carrying the same change-set. It's the same diff applied at a different point in history; the audit trail is intact across the two PRs as long as the follow-up PR body explicitly references the prior one and explains why a separate PR was needed.

Related: see [[feedback_auto_merge_workflow]] (the standing rule that PRs auto-merge on approval — don't ask user to merge manually). This memory is the gotcha-corollary.
