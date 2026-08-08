---
name: pattern-info-inband-dependency-probe-exceeds-poll-timeout
description: "monitoring 'fetch-info: HTTP Request timed out' on a service that curls fine = its /_info makes an in-band dependency call with a ~1s timeout, and lucos_monitoring allows /_info exactly 1s (fetcher_info.erl:238). A DEPENDENCY outage makes the healthy service report itself unreachable."
metadata:
  type: project
---

`lucos_monitoring`'s `/_info` fetch timeout is **exactly 1 second** — `lucas42/lucos_monitoring` `src/fetcher_info.erl:238`, `{timeout, timer:seconds(1)}`. `parseError(timeout)` renders as **`"HTTP Request timed out"`**.

So any service whose `/_info` makes a **live, in-band dependency call with a ~1.0s timeout** flips to "unreachable" the moment that dependency goes hard-down — while being perfectly healthy. 2026-08-08: `lucos_media_weightings` `/_info` went 1080–1261 ms (vs peers at 40–60 ms) purely because its `time-api-reachable` check spent its full 1.0s on the down `am.l42.eu`; back to 95–155 ms the minute lucos_time returned. lucas42/lucos_media_weightings#277.

**Why it matters beyond the false alert:** the failure lands on **monitoring's own `fetch-info` probe**, not on the service's declared check — so the service's `failThreshold` and `dependsOn` **never run**, even when correctly configured. `fetch-info` cannot meaningfully carry a `dependsOn`; it's the probe that establishes reachability at all. **The alert can therefore fire on the WRONG SERVICE FIRST** — on 2026-08-08 weightings alerted at 12:33:12Z, seven minutes *before* the actually-down lucos_time at 12:40:37Z.

**How to apply:**

- Symptom to recognise: monitoring says `fetch-info: HTTP Request timed out` but your own `curl` gets a clean 200. **Time it** — if it's 1.0–1.3s you have found this, not a network fault.
- Discriminate app-time from connect-time in one command: `curl -w '%{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total}'`. Connect ~ms + starttransfer ~1.1s ⇒ the app is generating slowly. Confirm by hitting the backend port directly on the host (bypasses DNS/TLS/router).
- **Check the depended-on service before writing this up as an independent failure.** Read the slow service's `/_info` `checks[*].debug` — a `ReadTimeout: HTTPSConnectionPool(host='X', ...)` names the culprit verbatim.
- Distinguish from [[pattern_happy_eyeballs_amplifies_syn_loss]]: SYN-loss is ~1.03s of *connect* and is intermittent; this is ~1.0s of *starttransfer* and is near-100% while the dependency is down.

Fix shape: `/_info` should publish a **cached** result the background worker refreshes, not make live calls with timeouts near the poller's budget. Related: [[feedback_failthreshold_lives_in_info]], [[pattern_info_endpoint_boundary]], [[pattern_dependson_deploy_window_only]].
