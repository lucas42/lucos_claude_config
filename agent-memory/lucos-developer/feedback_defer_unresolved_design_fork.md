---
name: feedback_defer_unresolved_design_fork
description: When an issue hands over an unresolved design fork, implement only the unambiguous half and name the open question in the PR body rather than deciding it silently
metadata:
  type: feedback
---

When triage hands off an issue containing an unresolved design/modelling choice (e.g. a render-vs-suppress
sub-decision), do not pick a side yourself. Implement the unambiguous part, leave the fork undecided, and
state the open question explicitly in the PR body/description. Hold the PR as a draft if the unresolved
choice affects mergeability.

**Why:** team-lead confirmed this was the right call on lucos_repos PR #468 (2026-07-15) — "the alternative
is that a modelling judgment gets made by whoever happened to be typing." The routing of *where* the question
should surface (e.g. which GitHub thread) can be wrong even when the decision to defer is right — that's a
triage-routing problem for the coordinator to fix, not a reason to have decided it yourself.

**How to apply:** When an issue or its design notes leave a genuine fork open, resist the urge to just pick
the more likely answer and ship it fully. Implement what's unambiguous, flag the fork clearly in the PR body,
and let it sit in draft/awaiting-decision rather than guessing. Don't worry about *where* the question gets
routed for an answer — that's the coordinator's job; your job is just to not silently resolve it.
