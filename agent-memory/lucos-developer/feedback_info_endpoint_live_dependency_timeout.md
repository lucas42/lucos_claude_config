---
name: feedback_info_endpoint_live_dependency_timeout
description: /_info must not make live in-band dependency calls with timeouts near lucos_monitoring's 1.0s poller budget
metadata:
  type: feedback
---

`/_info` handlers must not make a **live, in-band** dependency call as part of answering the request — especially not with a timeout anywhere near `lucos_monitoring`'s exactly-1.0s poller budget (`lucas42/lucos_monitoring` `src/fetcher_info.erl:238`). If the dependency is slow/down, `/_info` blocks past the poller's timeout and the service reports **itself** as unreachable even though it's healthy — this bypasses the service's own suppression config (`failThreshold`, `dependsOn`) entirely, because the failure lands on monitoring's `fetch-info` probe, not on the declared dependency check.

**Why:** Root-caused during the 2026-08-08 `lucos_time`/`lucos_dns` IPv6 subnet-collision incident (lucas42/lucos#281, source lucas42/lucos_time#351). `lucos_media_weightings`'s `/_info` called a dependency live with a 1.0s timeout; measured latency during the outage was 1080–1261ms vs 40–60ms for healthy peers. Filed as lucas42/lucos_media_weightings#277 by lucos-site-reliability, with a suggested fix: report a **cached** result that a background worker refreshes (media_weightings' worker already calls `getCurrentItems()` and publishes `last-weighting-update` — closer to "record what the worker learned" than new machinery).

**How to apply:** When implementing or reviewing any `/_info` endpoint (per [`references/info-endpoint-spec.md`](../../references/info-endpoint-spec.md)), check whether dependency-health fields are computed live per-request or read from a cache a background process refreshes. Prefer cached-read. If asked to implement lucas42/lucos_media_weightings#277 specifically, this is the pattern to follow. Don't file further estate-wide sweeps for this pattern myself — lucos-site-reliability owns incident follow-ups and asked to coordinate before filing (avoid duplicates); flag to them or team-lead instead.
