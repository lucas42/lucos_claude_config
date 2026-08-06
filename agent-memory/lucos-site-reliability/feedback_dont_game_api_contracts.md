---
name: Don't game API contracts to work around design issues
description: When a system's behavior seems wrong, address it at the source rather than passing dishonest values through an API to manipulate downstream behavior
type: feedback
---

When an API parameter has a designed meaning, **pass the truth and accept the consequences** — even if those consequences are unhelpful. If the consequences are wrong, fix the system at the source. Don't pass dishonest values through the API to manipulate downstream behavior.

**Why:** lucas42 caught this on 2026-04-29 (arachne#419 / arachne#420 / pythonclient#36). I'd "fixed" a too-narrow alert threshold by lying about a job's `frequency` to schedule-tracker (passing 3 days for a job that runs weekly, to game the server-side `frequency × 3` rule into a 9-day threshold). Then I made it worse by writing README guidance teaching others to do the same. lucas42's response: "the architecture here is that the script calling updateScheduleTracker says how often it runs, and the schedule tracker calculates its alerting threshold. Don't write a document telling people to reverse engineer the process."

The mistake had two layers:
1. **The fix itself was dishonest** — passing fake values to chase a desired side-effect, instead of passing real values and addressing any problematic side-effect at its source.
2. **The documentation codified the dishonesty** — turning a one-off workaround into systemic guidance for future callers.

**How to apply:** Whenever a fix involves passing a value that doesn't reflect the truth ("the job runs every 7 days but I'll claim 3 to manipulate the alert"), stop. Either:
- Pass the truth and live with the resulting behavior; or
- Address the system whose behavior you're trying to fix.

If you find yourself reaching for "I'll just pass X here to get Y to happen", verify that's the API's documented intent. If it isn't, you're gaming an implementation detail, and a future change to that detail will silently break your callers.

When in doubt, the architectural question is: "would this still be the right value if the downstream system's logic changed?" If the answer is no, the value is wrong.

## Routing around a DELIVERY MECHANISM vs routing around a CONTROL

During a degraded-platform incident, the same reasoning that justifies one workaround will appear to justify a second one that is categorically different. Draw the line explicitly (credit: `lucos-architect`, 2026-08-06 Actions outage):

- **`workflow_dispatch` to re-fire a stalled CodeQL run** — legitimate. It re-runs a check that was never a gate on *judgement*: CodeQL passes or it doesn't, and dispatching changes no policy. This routes around a **delivery mechanism**.
- **Merging by direct API call because `pull_request_review` webhooks are throttled** — not legitimate, even though it would work and the conditions genuinely appear met. `code-reviewer-auto-merge.yml` is the *enforcement point* for the estate's auto-merge approval policy (supervision via `unsupervisedAgentCode`; see `lucas42/lucos` `docs/adr/0013-…`, though note that ADR is **Proposed**, so the argument rests on the live mechanism it documents, not on the ADR's authority). This routes around a **control**, substituting my judgement for the gate.

**A fail-closed control being unreliable is the circumstance it exists for.** "The enforcement mechanism is degraded right now" argues for waiting, not for stepping past it. Retrying a throttled approval as many times as needed is the policy being *applied*, repeatedly — hand-merging is the policy being *skipped* once.

**How to apply:** when a workaround is proposed during an incident, ask what the bypassed component *decides*. If it only transports or schedules, routing around it is fine. If it adjudicates — who may approve, what must pass, who is notified — stop, and wait for it to recover. If something is still stuck after the platform is genuinely healthy, that's a real fault to diagnose, not licence to reach past the gate. Related: [[feedback_silent_fallbacks_are_a_security_risk]].
