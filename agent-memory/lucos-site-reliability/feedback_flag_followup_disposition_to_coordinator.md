---
name: feedback-flag-followup-disposition-to-coordinator
description: When wrapping up a follow-up issue I raised, flag the recommended disposition (close vs park) to the coordinator rather than setting the issue's open/closed state directly — board/triage disposition is the coordinator's lane
metadata:
  type: feedback
---

When finishing work on a follow-up issue **I raised**, do NOT set its open/closed state myself (close, reopen, not_planned, etc.). Post my summary comment and a *recommended* disposition (close vs park), then let the coordinator (team-lead) set the state.

**Why:** issue open/closed + board status is a triage-disposition call, which is the coordinator's lane (same family as [[feedback_labels_owner]] — labels are coordinator-only). On 2026-06-12 I closed `lucas42/lucos#242` `not_planned` directly after lucas42's "not now" decision. But team-lead had triaged it to Ideation/parked and told lucas42 it was "parked, revivable" — my close crossed that and made team-lead's statement to lucas42 stale, forcing a re-correction. I then *reopened* it on a crossed "parked-open" steer, then *re-closed* it once team-lead confirmed the settled state — a 3-toggle churn that a single "I recommend closing not_planned; your call" would have avoided.

**How to apply:** after finishing a follow-up I raised, comment with the outcome + recommended disposition and stop; leave the actual close/park/reopen to team-lead so the board and what team-lead has told lucas42 stay consistent. Compounding rule from the same incident: do not toggle issue state chasing crossed messages — wait for the coordinator's definitive word. Ties to [[feedback_never_revert_labels]] and the global "don't shift work to coordinator" balance (this is the opposite case — disposition genuinely IS the coordinator's, so hand it over).
