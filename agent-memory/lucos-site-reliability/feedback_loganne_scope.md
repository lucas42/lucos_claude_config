---
name: Loganne is for cross-estate events, not fine-grained instrumentation
description: Don't propose Loganne as the channel for latency or observability instrumentation; it's for coarse-grained, estate-interesting state changes only
type: feedback
---

Loganne is for **high-level changes that are interesting across the estate** — deploys, alerts, deliberate user-facing state transitions. It is NOT for fine-grained instrumentation: per-API-call timings, per-track-change events, or anything that fires at high frequency or whose signal is only meaningful inside one system.

**Why:** lucas42 rejected my proposal (lucas42/lucos#126) to lean on Loganne timestamps as the channel for end-to-end latency instrumentation across scenes / media_manager / seinn. His exact words: "It should be used for high-level changes which are interesting across the estate, not every single API call that's specific to a one system." Two of the three events I'd proposed (`collectionPopulated`, `nowPlayingChanged`) were rejected on noise/scope grounds; the issues were closed `not_planned`. Only `sceneActivated` (a coarse user-action) survived.

A second related point lucas42 made: my comment thread on lucos#126 jumped straight to "use Loganne" without enumerating alternatives. "The comment thread here doesn't seem to address the pros and cons of that approach. It's just sort of assumed as the solution." Fair critique — a tool choice for estate-wide instrumentation deserves a comparative analysis, not a default to whatever's nearest to hand.

**How to apply:**

When proposing instrumentation, observability, or measurement approaches, evaluate channels by their fit to the signal characteristics:

- **Loganne**: coarse user-facing state changes; events that other systems would care about; low-to-moderate frequency. Examples that fit: `deploySystem`, `monitoringAlert`, `deviceSwitch`, `collectionSwitch` (when modelled as a single completion event), `sceneActivated`. Examples that DON'T fit: per-track playback transitions, per-API-call timings, internal sub-step events.
- **In-process logs / app logs / access logs**: high-frequency operational data, single-system context, structured for grep-and-parse rather than feeds.
- **Dedicated metrics endpoint**: numeric time-series data, intended for graphs and aggregation.
- **OpenTelemetry tracing**: cross-system request correlation with detailed spans, when the question is "what happened during this single request" rather than "what's happening in the estate".

When the question is *"how long did X take?"* across distributed systems, default to a tracing/correlation approach, not Loganne. When the question is *"what high-level thing did the user do?"*, Loganne is appropriate.

**Modelling rule for state transitions in Loganne**: a single state change is one event, fired when the change is fully complete. Don't decompose into start/end pairs (`collectionSwitch` + `collectionPopulated`) — that's instrumentation in disguise. The single event's timestamp is the moment the new state is observable. For lucos_media_manager#238 specifically, this means `collectionSwitch` fires once the new tracks are populated, not on `setFetcher()`.

**Compounding rule for tool-choice proposals**: when proposing a tool/channel/approach for cross-system work, enumerate at least two viable alternatives with pros and cons before recommending one. "Default to Loganne because that's where Loganne lives" is not a reasoned choice.
