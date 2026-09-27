---
name: pattern-avalon-dns-1s-stall-via-public-resolvers
description: avalon containers resolve via Docker DNS → 8.8.8.8/OVH with no local cache; ~0.5–1.5% of lookups stall ~1,030ms. That's what fails sub-1s probe budgets (seinn media-manager), not the target.
metadata:
  type: project
---
On 2026-09-27, seinn's `media-manager` probe failures (800ms budget) were traced to ~1s DNS stalls resolving `ceol.l42.eu`, not to media_manager (JVM pause max 23.8ms), the router, TCP (TCPSynRetrans 0) or TLS (max 28ms). Filed lucas42/lucos_media_seinn#639 (raise budget to 2000ms). The alert amplification is lucas42/lucos_monitoring#303.

**Why:** containers use 127.0.0.11 (Docker DNS), which forwards to avalon's upstreams 8.8.8.8 + 213.186.33.99 with no local cache. Google was directly seen answering in ~1,028ms (c-ares, one attempt, so not packet loss). Our authoritative servers never exceeded 14ms. `RES_OPTIONS=single-request` didn't help, which rules out glibc's parallel A/AAAA race.

**How to apply:**
- A sub-1s probe failing at exactly its budget, with the request **absent from the router access log**, means a DNS/TCP/TLS phase stall. Time the phases with a Node script via `docker exec -i <c> node -` (dns.lookup, net.connect, tls.connect).
- avalon has **no `dig`**. Use Node's `dns.Resolver` with `setServers` for per-server queries. [[pattern-probe-measures-then-discards-latency]]
- Loganne `since=today` caps at ~N events **from the start of the day**, so the newest events are missing. For recent state changes, read `docker logs lucos_monitoring | grep "state changed"`.
- Unverified: monitoring's rotating single-reading `fetch-info` timeouts may be the same stalls.
