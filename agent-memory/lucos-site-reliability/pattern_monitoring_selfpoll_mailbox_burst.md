---
name: monitoring-selfpoll-mailbox-burst
description: lucos_monitoring's own /_info blocks behind its state server's once-per-cycle mailbox burst (depth 10-16, ~3s in 60 at :24-:26) — plus the erl_call recipe, router-vhost attribution, and the sampling-rate trap that nearly killed the diagnosis
metadata:
  type: project
---

**`lucos_monitoring`'s self-poll flap = its own `/_info` blocking behind its own state server's mailbox.** Confirmed 2026-08-09 by co-timed measurement (lucas42/lucos_monitoring#298). Hypothesis was `lucos-architect`'s, offered with a falsifier; the falsifier was run and did **not** fire.

**Why:** `server.erl:254-257` serves `/_info` with two synchronous `gen_server:call`s into `StatePid`; every fetcher `cast`s into that same process (2 casts × 55 systems per cycle). `/_info` costs **~1.8ms** for 57 of every 60 seconds and **>1.5s** for the other ~3, when the mailbox bursts to **10-16** at **:24-:26 past the minute** (the poll cycle). Only the self-poll is affected — it is the one endpoint whose response time is a function of monitoring's own workload. `/api/status` is far less affected (shares `{fetch, all}` only; `/_info` also does `{fetch, poll_stats}` + `encodeInfo`). Scaling property: **more systems ⇒ slower self-report.** Never alerts — `CONSECUTIVE_UNKNOWNS_THRESHOLD` = 5, deepest run 4; `buffering` IS that gate holding. Retracted en route: "permanent", "not self-clearing", NAT66 hairpin (real but only in the 4-min post-recreate settling window).

## ⚠️ The sampling-rate trap (generalises well beyond this)

**A ~3s burst inside a 60s cycle is a 5% duty cycle, and any probe slower than the burst returns a clean, plausible, WRONG negative.** Two probes on this ticket did:
- 25 back-to-back hand fetches → all clean. They sit at one phase of the cycle; absence of evidence, not evidence of absence.
- Sampling `message_queue_len` every 2s *after* each request → only ever 0 and 1. I nearly published "queue empty during slow response", which would have killed a correct hypothesis. **Sampling at 50ms inside the node found depth 14 in identical conditions.**

**How to apply:** before accepting a negative from a periodic-phenomenon probe, ask *what is the duty cycle, and is my sampling interval shorter than the event?* Sample **inside** the system at high frequency and bucket, rather than one-shot from outside. Co-time the two series (epoch seconds) instead of taking one just-after-the-other. See [[pattern_probe_measures_then_discards_latency]], and the ops-checks "prove your probe can return a positive" rule.

## erl_call recipe (read-only, safe — NO remote_console)

`remote_console` risks killing the node on a bad shell exit. `erl_call` is a one-shot RPC from a hidden node — no shell attached.

```sh
# node `prod`, cookie `prod` (from /web/releases/1.0.0/vm.args); binary NOT on PATH
docker exec -i lucos_monitoring /web/erts-17.0.4/bin/erl_call -sname prod -c prod -e <<'EOF'
erlang:process_info(list_to_pid("<0.574.0>"), message_queue_len).
EOF
```
`command -v erl` returns nothing — **false negative**, release lives at `/web/erts-17.0.4/bin/`. `StatePid` is **not registered**; find it by `$initial_call` in each process's dictionary (`{monitoring_state_server, init, 1}`). Note pids change on restart — re-derive, don't cache. No `curl` or `ps` in the image; probe from the avalon host against the container IP (`http://172.16.10.2:8015/_info`) to isolate response *generation* from DNS/TLS/router.

## Attributing `fetch-info` failures to a system

`monitoring_state_server.erl` `replaceUnknowns/4` logs `Not sending alert for ~p …` with the **check name but NOT the system** — every notice is anonymous. And it fires **twice per failed fetch** (two reporting sources), so counting log lines double-counts.

**Use the router access log instead** — `UA "lucos_monitoring"` + status `499` (monitoring gave up before the response), and read the **vhost** field:
```sh
docker logs --since <T> lucos_router 2>&1 | grep lucos_monitoring | grep _info \
  | awk '{for(i=1;i<=NF;i++) if($i ~ /^"(GET|HEAD)/){st=$(i+3); break}} st!=200 {print $4, $6, st}'
```
2026-08-09 result: 42 notices = **21 real failures** = 18 `monitoring.l42.eu` + 3 `backups.l42.eu`. `/api/status` does NOT expose `consecutiveUnknownsCount`, but a live flap IS attributable by polling it for `status == "buffering"`.

**Clustering EXPLAINED (2026-08-09, architect's herd hypothesis + source):** no jitter anywhere. `fetcher_info`/`fetcher_circleci`/`fetcher_ports` spawn **one process per target**, each `sleep(60s)` after its own work ⇒ true period = 60s + own duration ⇒ they start phase-aligned at boot and **drift apart**, which is the observed decay (failures 23:53→02:47, straggler 07:09, then clean). **BUT `fetcher_scheduled_jobs` is ONE process** that fires a cast per system back-to-back in a tight `maps:foreach` then sleeps 60s — **structurally cannot spread, ever.** So "sample depth late; flat kills the hypothesis" is an INVALID falsifier: it can never go flat.

**Production render cost (measured, don't use the 25ms dev-box figure):** `timer:tc` over `view:render_dashboard_block/1` against real 55-system state, n=15 → **min 82ms / p50 105ms / max 134ms** (~4.2x dev box). `schedule-tracker /jobs` = 37 jobs over **11 systems** ⇒ **11 × 105ms = 1159ms of serialised rendering in one go, exceeding the 1000ms `/_info` budget by itself.** Reconciles with measurement: observed burst floor 10-11 (= the 11 casts), peak 13-16, and 16 × 105ms = 1686ms vs the 1551ms slow `/_info` actually recorded (within 9%). Recipe: `gen_server:call(P,{fetch,all})` returns a **list** of 55 maps; pass it straight to `view:render_dashboard_block/1`. ⚠️Wrap in try/catch — an uncaught error dumps the ENTIRE state (~590KB) into your output.

**Separate system — ALREADY TRACKED, do not re-file:** `lucos_backups` logs `Tracking Backups...` at exactly **HH:07:00** hourly and its `/_info` is unavailable during it (**3 of the 10 runs** 05:07–14:07 on 2026-08-09; blocking window measured 15s and 20s from its own access log). This is **lucas42/lucos_backups#374** — my own ticket from 2026-07-18, Ready, Owner `lucos-developer`, one-line `ThreadingHTTPServer` fix, raised Low→Medium 2026-08-09. Cause is head-of-line blocking on a single-threaded `HTTPServer`, **not** `/_info` cost — its handler is fine. Same family as lucas42/lucos_media_weightings#277 and covered by the estate rule proposed in lucas42/lucos#288.
