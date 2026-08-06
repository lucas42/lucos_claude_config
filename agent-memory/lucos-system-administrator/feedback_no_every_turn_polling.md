---
name: feedback-no-tight-polling-for-cosmetic-waits
description: Match monitor/poll frequency to how fast the watched state changes and what it actually unblocks — not just to how cheap each individual wake is
metadata:
  type: feedback
---

Don't run a tight poll loop (e.g. every 2 minutes) for a wait whose outcome is cosmetic or low-stakes, even though each individual wake is cheap in isolation.

**Why:** On 2026-08-06 I set a Monitor polling GitHub's status API every 2 minutes to catch the moment a platform-wide Actions incident resolved, so I could re-run two `convention-check` jobs. At the time (started ~17:53 UTC) the incident looked fresh enough it might clear soon. Team-lead had me stand it down at the 3-hour mark: the incident was still `investigating`/`major_outage` with no sign of imminent resolution, and the thing I was waiting to do was purely cosmetic — the check was confirmed non-required, both PRs were already approved and `mergeable: true`, nothing was actually gated on it. A ~2-minute wake cycle running for potentially many more hours to improve CI history accuracy on merge-approved PRs is a poor trade, independent of each wake's low cost.

**How to apply:** Before arming a tight poll loop, weigh two things together: (1) how fast is the watched state actually likely to change (an "any minute now" situation vs. a multi-hour platform incident with a track record of slow updates), and (2) what does resolving it actually unblock (a real gate vs. pure tidiness/history accuracy). If either answer trends toward "slowly" and "nothing," don't poll tightly — log the follow-up (with enough detail to act on later — exact commands, IDs, current state) and let it surface on the next natural check-in (a scheduled ops-check run, a status ping) instead of an active wake loop. Not a reason to avoid Monitor for genuinely time-sensitive waits — just recognise when a wait has quietly become a low-stakes background item and downgrade it. See [[github-actions-outage-diagnostic-signature]] for the specific incident this was learned on.
