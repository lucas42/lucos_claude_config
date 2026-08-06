---
name: pattern-router-log-gap-analysis
description: "To prove a service stalled (vs was merely slow, vs the host wobbled), extract every router access-log timestamp for its vhost, find inter-request gaps, then compare against router-wide throughput in the same window"
metadata:
  type: reference
---

The router's nginx access log has **no `$request_time`**, so it can never tell you how *long* a request took. But it does record every *completed* request, which lets you answer a different and often better question: **did this service stop responding at all, and was it only this service?**

**Step 1 — extract every timestamp for the vhost and find gaps:**
```bash
ssh avalon.s.l42.eu "docker logs --since <T> lucos_router 2>&1 \
  | grep -F '<host>.l42.eu' | sed -E 's/.*\[([^]]+)\].*/\1/'" > /tmp/ts.txt
# parse '%d/%b/%Y:%H:%M:%S', sort, print consecutive deltas >= N seconds
```
Pick the gap threshold from the vhost's normal cadence (long-poll clients and `/_info` pollers give most lucos services a request every 1–3s, so ≥12s is a safe floor). Report it as "N requests over H hours, exactly K gaps ≥Xs" — the denominator is what makes it evidence rather than an anecdote.

**Step 2 — the decisive control. Count router-wide requests per second in the same window:**
```bash
docker logs --since <T0> --until <T1> lucos_router 2>&1 \
  | sed -E 's/.*\[([0-9]{2}\/[A-Za-z]{3}\/[0-9]{4}:[0-9:]+) .*/\1/' | awk -F: '{print $2":"$3":"$4}' | uniq -c
```
If the estate-wide stream is continuous through the gap, the host, the kernel, the network namespace and nginx are all exonerated and the stall belongs to that one container. If it *also* gaps, you have a host-level event — stop blaming the app.

**Two things this separates that otherwise get conflated:**
- *slow but successful* — a probe times out but there is **no** router gap (the response landed just over the client's budget)
- *actually stalled* — the probe times out **and** the router shows a hole

**⚠️ PRECONDITION — avalon's router is not a universal estate oracle.** It only logs vhosts *it* serves. Before reading a zero-line grep as "the requests never left", confirm the target actually routes through avalon: `lucos_configy` `config/systems.yaml` → the system's `hosts:` list, plus the caller's origin env var. A cross-host probe (caller on avalon, callee on xwing/salvare, over the public name) never touches avalon's router, so the blank is the probe failing, not the traffic being absent. **Always run the positive control** — grep the same vhost over the last 30 minutes; if that is also 0, you have proven your probe broken, not your hypothesis right. Bit me 2026-08-06 chasing lucos_time's `media` check: `lucos_static_media` has `hosts: [xwing]` and `MEDIAURL=https://staticmedia.l42.eu/time`, so avalon's router had never seen a single one of those HEADs. Corollary for the vhost you *can* see: when the router is blind to a probe, the check's own `debug` string is the only record it ever ran — which is precisely why discarding `error.cause` matters (lucas42/lucos_time#348).

**Practical notes:** the router log is ~5.7M lines; `grep` over it takes minutes, so run it with `run_in_background: true` and read the output file. Filter with `grep -F` on the vhost before any sed. `docker logs --until` excludes the boundary second, so widen the window before concluding a gap runs to the edge.

First used 2026-08-02 → lucas42/lucos_media_manager#283: 59,699 requests to `ceol.l42.eu` over 50.4h contained exactly one gap ≥12s (24s on 08-01 20:42:51→20:43:15) while router-wide throughput never dropped below 1 req/s. That single control killed the "host blip" hypothesis outright and closed a caveat I'd left open on lucas42/lucos_media_seinn#583.

Related: [[pattern_access_log_first_for_webhook_bursts]], [[feedback_avoid_coincidence_default]], [[pattern_probe_measures_then_discards_latency]].
