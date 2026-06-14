---
name: defense-in-depth-reverts-to-baseline
description: Before framing a control's failure as high-leverage/urgent, check if it's defence-in-depth over an independent control that still holds — if failure reverts to an accepted baseline, the gap is low-value
metadata:
  type: feedback
---

Before pitching the detection/remediation of a security or reliability gap as "highest leverage" / "urgent" / "silently broken for N days", ask: **is the failed control defence-in-depth over an *independent* control that still holds?** If so, its failure reverts to an **already-accepted baseline**, not below it — and the gap is low-value regardless of how bad "silently bypassed" sounds.

**Why:** 2026-06-15, lucas42/lucos_monitoring#285. I proposed a standing perimeter-reachability monitor as the firewall#21 follow-up and framed it as "highest durable leverage — silent for 6 days." lucas42 pushed back: the firewall is defence-in-depth *over app-layer auth*; every sensitive service (contacts, locations, arachne, eolas) was independently auth-gated, so the bypass exposed nothing beyond the pre-firewall baseline he'd run the estate on for years. A control that fails open reverts to baseline; it doesn't drop below it. My framing implied an exposure window that didn't exist. He was right; I recommended closing it.

**How to apply:**
- Proportionality = the cost of the failure mode *actually occurring*, NOT how alarming "perimeter silently bypassed" reads. Compute the real delta vs the accepted baseline.
- A second-layer control failing to an already-tolerated state is low-value to monitor. The trigger that flips it: a service whose **only** protection is that control (no independent layer) — then its correctness is load-bearing and a check earns its place. State that revisit-trigger explicitly.
- The thing that makes a check *correct* often makes it *heavy* (e.g. the off-host vantage needed to validate an external-origin firewall path → per-host deployment). When correctness forces heavy infra for a low-value signal, that's a close-it signal. Offer a change-time spot-check (runbook step) over a standing system.
- Sits under Self-Verification #4 (proportionate to actual scale/risk); related to [[feedback_check_value_when_fix_complexity_grows.md]] (that's fix-complexity-vs-value; this is threat-overstatement-vs-baseline).
