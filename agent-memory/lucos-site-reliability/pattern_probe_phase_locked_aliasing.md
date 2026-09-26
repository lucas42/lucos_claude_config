---
name: pattern-probe-phase-locked-aliasing
description: A 60s monitoring probe is phase-locked to any traffic whose period divides 60s, so "the next log line after each failure lands at a fixed offset" is aliasing, not latency
metadata:
  type: pattern
---

When correlating probe failures against an access log, a **constant offset** between each failure and the next matching log line looks like proof of a fixed-duration stall (e.g. "ceol took 10.9s"). Check the background traffic's period first. monitoring polls `/_info` every **60s**. Any other stream with a period dividing 60s (a 10s long-poll cycle, a 30s heartbeat) keeps the same phase relative to the probe, so the "next line" sits at a fixed offset whatever the latency.

**How to apply:** histogram the inter-arrival times of the background stream before reading anything into the offset. If its period divides the probe interval, the offset carries no information. The nginx format here has no `$request_time`, so the router log can't give you latency anyway.

Grounding: 2026-09-26 lucas42/lucos_media_seinn#583. 45 of 75 failures had a seinn `/v3/poll` completion at +10.87–10.90s, and seinn's poll traffic runs on a 10s cycle. Related: [[pattern-probe-measures-then-discards-latency]], [[pattern-stale-line-race-needs-exposure-not-absence]].
