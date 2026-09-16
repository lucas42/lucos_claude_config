---
name: sweep-deadline-vs-interval
description: Polling services that reuse the refresh interval as the sweep deadline starve the tail of their list, and silently disable their own failure detection for it (lucos_root#158)
metadata:
  type: reference
---

**"How often to sweep" and "how long a sweep may take" are different numbers.** A sequential poller whose sweep context timeout equals its refresh interval cannot finish once a few targets fail slowly, and if it restarts from index 0 each cycle, everything past the cut-off is **never polled at all** — a stable starvation state, not a transient.

Worked example — `lucos_root` (Go, homepage service list), found 2026-09-16 during the avalon rebuild:

- `refreshInterval = 60s`, `fetchTimeout = 10s`, 31 domains from configy, polled sequentially, sweep given `context.WithTimeout(ctx, refreshInterval)`.
- Worst case sweep = 310s against a 60s budget. ~6 slow-failing targets exhausts it — an ordinary bad day, not just an incident.
- Measured: full sweep 142.6s; cut-off landed at position ~11–12; the page rendered exactly the homepage-eligible services in positions 1–11, while up-and-fast services at #17/#23/#26/#31 stayed invisible for 10+ cycles.
- Startup sweep has the same flaw more mildly: 5-minute budget vs a 310s worst case.

**The second-order harm is the one to look for.** A target never *reached* has neither its success path nor its `recordFailure` path invoked, so its failure clock never starts: it keeps its last-known state indefinitely, never crosses the unavailable threshold, and never emits the failure telemetry. The monitoring designed for the system silently stops covering the part of the list most likely to need it.

**Diagnostic that worked:** probe every target in the source list's order, accumulate the elapsed times, and predict which targets fall inside the budget. If the predicted rendered set matches the observed rendered set exactly, that's near-conclusive. The discriminating check against "those targets had only just recovered" is to confirm they stay absent across many refresh cycles while answering fast.

**Design smell to check for elsewhere in the estate:** any fan-out poller where one constant serves as both cadence and deadline. Fixes: size the sweep deadline to the list (or drop it — per-fetch timeouts already bound each call) and let the ticker skip a tick while a sweep runs; bounded concurrency (4–6) so one hanging target can't consume everyone's budget; resume from where the last sweep stopped; and expose sweep completeness (targets polled vs listed, age of oldest successful poll) in `/_info`.

Related: [[info-endpoint-observability-inversion]], [[docker-healthy-not-reachability]].
