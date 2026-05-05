---
name: Compare channels honestly when proposing instrumentation
description: When asked to recommend an instrumentation/telemetry approach, do the channel comparison up front rather than anchoring on the most familiar option (Loganne)
type: feedback
---

When asked to recommend an instrumentation/telemetry approach, do an honest comparison of candidate channels (Loganne vs service logs vs `/_info` vs tracing vs new endpoint) **before** writing the recommendation. Don't anchor on Loganne just because it's the existing infrastructure.

**Why:** On lucas42/lucos#126 (2026-05-05) I recommended a three-Loganne-event approach (`sceneActivated`, `collectionPopulated`, `playbackTransition`) without comparing alternatives. lucas42 pushed back: per-API-call timestamps and per-track events aren't what Loganne is for — it's a curated cross-estate state-change log. Triage had to be unwound (two issues closed `not_planned`). His direct quote: *"The comment thread doesn't seem to address the pros and cons of that approach. It's just sort of assumed as the solution."* That's the exact failure mode to avoid.

**The principled split** (settled in the rework): **Loganne carries cross-estate state changes; service logs carry local execution detail.** A `console.log` in seinn for per-track transitions is fine; a Loganne `playbackTransition` event for the same thing isn't. The distinction is volume tolerance, audience, and significance — not the literal level of detail.

**How to apply:**
- Before recommending Loganne for new instrumentation, ask: is this a state change interesting estate-wide, or is it execution detail local to one service? If the latter, service logs are the right channel.
- When the question is "measure latency end-to-end," the candidate-channel list always includes: Loganne, service logs, `/_info` counters/histograms, dedicated endpoint, distributed tracing. Compare each on infra cost, principled fit, and forward-compat — don't pick one without weighing the others, even when the team is steeped in Loganne.
- A useful framing test: is this a one-off diagnostic or ongoing observability? One-off diagnostics tolerate manual log-reading; ongoing observability is what justifies the infrastructure cost of tracing. Don't oversize the solution.
- A property of a single event (e.g. `firstBatchLatencyMs` on `collectionSwitch`) is fair game on a Loganne event — that's not telemetry contamination, it's descriptive metadata. Per-event vs per-call is the line.
