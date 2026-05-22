---
name: risk-webhook-fanout-amplification
description: Loganne webhook fan-out can amplify a client-side error burst into backend DoS pressure — observed in 2026-05-22 seinn incident
metadata:
  type: project
---

## Risk Pattern: Webhook Fan-out Amplification from Client-Side Error Bursts

**Observed:** 2026-05-22 seinn incident (docs/incidents/2026-05-22-seinn-eviction-failure-webhook-burst.md)

A degraded Chrome tab in `lucos_media_seinn` caused ~70 successive track decode failures. Each failure emitted a `trackUpdated ... errored` event via loganne, which fanned out to all registered webhook subscribers. This produced four `webhook-error-rate` monitoringAlerts despite the root fault being purely client-side and ephemeral.

**Threat model implication:** If an attacker could induce a comparable client-side error rate (e.g. by serving malformed audio, injecting bad responses, or triggering client-side decode loops), the same fan-out path would amplify their request volume against loganne's webhook subscribers:
- `arachne.l42.eu`
- `media-weighting.l42.eu`
- `ceol.l42.eu`

**Limiting factors:**
- Loganne auto-retry is once-then-give-up → ~2× amplification per event (low)
- seinn is single-user (attack surface is limited)
- Inducing the error state requires either compromising media content or the client session

**Assessment:** Not currently worth raising as a distinct security issue. The fan-out architecture is load-bearing and the amplification factor is modest. Worth watching if webhook subscriber count grows or if loganne becomes accessible to untrusted content sources.

**Why:** Recording to inform future reviews of loganne webhook fan-out behaviour, particularly if new subscribers are added or if retry logic changes.

**How to apply:** When reviewing loganne subscriber additions or retry configuration, consider whether the new subscriber can absorb 2× burst from a single upstream client fault. Flag if retry multiplier increases beyond 2×.
