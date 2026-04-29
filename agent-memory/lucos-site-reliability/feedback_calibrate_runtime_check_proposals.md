---
name: Calibrate impact-vs-effort before proposing runtime monitoring checks
description: When filing or recommending a monitoring/check follow-up, weigh the failure mode's actual impact against the build+maintenance cost of the check
type: feedback
---

When filing or recommending a runtime monitoring check (a new probe, a new check on `lucos_monitoring`, a new health-check tier, etc.) as an incident follow-up, the proposal must include explicit impact-vs-effort calibration. Don't assume "more detection is always better."

**Why:** lucas42 closed `lucas42/lucos_monitoring#207` (the runtime UI-integrity check follow-up from the 2026-04-29 eolas/contacts incident) as `not_planned`, overruling the consensus of three personas (architect, ux, sre) who'd agreed the issue should sit at `priority:low` until a CI-blind regression surfaced. The reasoning:

> the effort needed to monitor this is disproportional to the impact. All that happened was some internal admin pages didn't look nice. Once it was noticed, we were able to fix it with 3 lines of code. That's fine. No need to over-engineer a monitoring platform which tries to understanding front-end asset loading.

Three personas defaulted to "the failure was real → build a check for it." The calibration we collectively missed: an admin-only styling failure that was quickly diagnosable from a 404 and fixable in 3 lines is not in the same impact category as a user-facing outage. The cost of building and maintaining the check exceeded the cost of the failure it would have detected.

**How to apply:** before filing a follow-up issue for a runtime monitoring check (or before recommending one in a comment), state explicitly:

1. **Failure-mode impact**: what does this failure look like in the wild? Who sees it? How long would it likely persist before being noticed by ordinary observation? What's the recovery cost once spotted?
2. **Check effort**: what does it cost to build the check, and what's the ongoing maintenance burden (per-service config, schema evolution, false-positive triage)?
3. **The honest comparison**: if the failure mode is "internal-only inconvenience, recoverable in N lines once noticed" and the check is "an estate-wide monitoring extension with per-service config", lean toward "accept the risk, don't build the check."

If the proposal can't honestly justify the effort given the impact, don't file the follow-up. A build-time CI assertion (cheap, no runtime burden, fails the deploy) is often a sufficient defence even when a runtime check would catch slightly more failure modes.

This is *not* "stop proposing runtime checks." It's "include the calibration explicitly so the trade-off is visible to whoever decides priority." The default of "more detection is better" is wrong; the right default is "every check has a maintenance tax, justify the tax."

**Where this came from:** team-lead message 2026-04-29 (post-incident), relaying lucas42's overrule on `lucos_monitoring#207`. Substantive feedback to SRE persona (and to architect, ux to lesser extent) — the three of us agreed unanimously on a position lucas42 considered over-engineering.
