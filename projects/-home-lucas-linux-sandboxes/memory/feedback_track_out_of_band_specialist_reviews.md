---
name: feedback_track_out_of_band_specialist_reviews
description: "When the coordinator dispatches a specialist (security/SRE) review out-of-band, it owns tracking that PR to actual merge — the code-reviewer's final verdict is NOT auto-triggered by the specialist's approval"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bbf332f2-a3a1-44cf-9478-3ce93c92883c
---

On mandatory-review repos (e.g. lucos_aithne), the code-reviewer posts a `COMMENT` and **defers its final APPROVE until the specialist (security/SRE) signs off** — then it must be **re-requested** to post the final verdict. Nothing auto-re-triggers the code-reviewer when the specialist approves. So a PR can silently sit in "specialist-approved + code-reviewer-commented" (looks reviewed, is NOT approved-to-merge) indefinitely.

**Why:** 2026-07-08, lucas42/lucos_aithne#300 (the login-critical email-claim PR) sat **3h16m** un-merged — security approved at 14:09, code-reviewer didn't finalise until 17:25 (right after a nudge). The `pr-review-loop` puts the re-trigger on the implementation teammate (Step 4 → re-request code-reviewer after the specialist), but the developer had gone idle after opening the PR. Compounding it: I'd been dispatching the security reviews **out-of-band** (coordinator SendMessage) to keep things moving — which meant neither the developer's loop nor I clearly owned re-triggering the code-reviewer, and I'd relayed "in review" and stopped tracking. It only surfaced when lucas42 hit the login error.

**How to apply:**
- If you dispatch a specialist review yourself (out-of-band from the implementation teammate's loop), **you own driving that PR to merge** — after the specialist approves, re-request/nudge the code-reviewer for its final verdict, then confirm the merge. Don't relay "in review" and move on.
- For any **blocking / critical-path PR**, track it to an actual `merged: true`, not to "reviewers requested." A COMMENT + a specialist APPROVE is not a merge.
- Better: leave the specialist dispatch to the loop-driver (developer/sysadmin) so loop ownership isn't fragmented — or explicitly hand tracking back to them. Relates to [[feedback_changes_requested_not_a_hard_block]].
