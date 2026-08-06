---
name: stacked-pr-unprotected-branch-hazard
description: Stacking a PR on another unmerged PR's branch is fine, but on an unprotected repo the child can auto-merge into the parent branch before the parent merges, discarding the parent's in-flight approvals
metadata:
  type: feedback
---

Stacking a new PR's base on another unmerged-but-approved PR's branch (rather than `main`) is a good move when both touch the same file and the parent is blocked on something unrelated to code (e.g. a CI outage) — team-lead confirmed this was the right call on lucos_worlds#75 (based on #73), and GitHub retargeted the child's base to `main` automatically once the parent merged, as expected.

**The hazard team-lead flagged, confirmed as real:** an unprotected branch (i.e. not `main`, no required-checks/required-review gate) has *nothing* holding a stacked PR back from auto-merging into it the moment its own approval clears — even mid-flight, while the parent PR's own approvals/CI are still resolving. On lucos_worlds#73/#75 this created a live race: #75 (targeting #73's branch) was `CLEAN` and approved while #73 was still finishing its CodeQL run; had #75's approval webhook drained before #73 merged, #75 could have auto-merged straight into #73's branch, moving #73's head and silently discarding both PRs' approvals right as they were about to clear. #73 won the race by ~90 seconds — not something either of us had engineered, just luck of the timing.

**Why:** `main` carries the required-check/review gate that blocks premature merges; a feature branch used as another PR's base carries no such gate by default, so branch-protection-style safety doesn't propagate to it.

**How to apply:** when stacking a PR on another unmerged PR's branch, treat the merge ordering as unprotected — either watch both PRs actively until the parent merges, or flag the race explicitly to whoever's tracking the outage/merge sequence (as team-lead was doing here) so a human or the SRE monitor is aware two approvals are converging on the same window. Don't assume "both approved" is safely inert just because the child's base isn't `main` yet.
