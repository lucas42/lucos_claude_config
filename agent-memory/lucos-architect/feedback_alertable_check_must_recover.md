---
name: alertable-check-must-recover
description: An alertable check must reflect current recoverable state, not cumulative history; anchor its clear condition to the real heal event, not a restart
metadata:
  type: feedback
---

# An alertable check must be able to recover on its own

A monotonic / cumulative counter (e.g. "failures since restart") is the **wrong primitive for an alertable check**. A count of past failures never goes back down, so the only thing that clears the alert is a process restart/redeploy. That produces a check that sits red long after the underlying problem is fixed — a false-positive generator that trains responders to ignore it.

**Why:** lucas42's correction on lucas42/lucos_arachne#702 (2026-06-30). My first "Option A" surfaced the existing `failed_ingestion_count` (monotonic, in-memory, "since last restart") as a check. He pointed out the Ewokese failure was fixed entirely upstream in lucos_eolas with *no arachne redeploy*, so the alert "would remain red long after the fix was in place and the data had been reingested."

**How to apply:** When designing any check that should page/alert:
- Make `ok` reflect **current state**, not history. Ask "what real-world event resolves this?" and anchor the clear condition to *that event*, not to a restart or a manual ack.
- For ingest/processing failures backstopped by a reconcile: `ok:false iff a failure has occurred since the last successful full reconcile`. The reconcile is the heal event, so it clears the check automatically — and green honestly means "no outstanding gap right now," even if a latent bug remains (detecting the bug is the job of a CI regression test, not a runtime monitor).
- If the failure-recording process and the heal-signalling process don't share memory (e.g. separate processes in one container — they share a **filesystem, not memory**), cross the boundary with a minimal shared signal (a touched marker file), not durable per-event state (which would be a dead-letter queue / Option C).
- Anchor the clear to the *fully-successful* heal only. Watch for an **unconditional** success tick that also fires on partial success — anchoring there clears the check after a heal that left gaps. (#702: ingest.py's end `updateScheduleTracker(success=True)` runs even on `has_failures=True`; the marker had to go in the `not has_failures` cleanup branch.)
- Tier it to impact: a self-healing, low-impact gap → non-paging/notable, low failThreshold; runbook line that **green = "data healed", not "bug fixed"** so auto-clear isn't a code-layer hand-wave ([[reference_info_endpoint_network_only]] is unrelated; see "no transient dismissals").

Related: this is the recoverability complement to [[feedback_detector_inverse_failure_mode]] (a detector blind to the inverse failure) — here the detector is blind to *its own recovery*.
