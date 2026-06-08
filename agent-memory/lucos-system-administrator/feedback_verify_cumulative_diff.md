---
name: feedback_verify_cumulative_diff
description: Before un-drafting a PR and adding Closes #N, verify the cumulative diff against main contains every fix the PR body claims
metadata:
  type: feedback
---

Before un-drafting a PR (or setting `Closes #N` in its body), run `git diff main...HEAD` and confirm the net diff contains every change the PR description claims.

**Why:** After force-pushes or shared-branch editing, a commit can edit the wrong location (e.g. a section PR #229 already fixed) and silently disappear from the net diff against main. The PR body says "Closes #N" but the actual change isn't there. Discovered when taking over architect's draft PR #232 on branch `fix-adr0007-forward-policy-and-cross-stack`: my cross-stack commit `2bb1fd8` edited the Decision section (already correct in main), so it contributed nothing to the net diff, while the Negative bullet (the actual error) remained uncorrected.

**How to apply:** Any time you're about to un-draft a PR or claim it closes an issue — especially on branches with multiple contributors or force-push history — run `git diff origin/main...HEAD -- <file>` and verify each claimed fix is actually present in the net diff, not just present as a commit.
