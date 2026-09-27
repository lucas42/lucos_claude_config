---
name: pattern-avalon-dns-1s-stall-via-public-resolvers
description: Since the 09-16 rebuild, avalon's resolved.conf has DNS=8.8.8.8 (the old host used only OVH). Google answers ~1 in 300 lookups after ~1,030ms, which fails sub-1s probes (seinn media-manager). Fix proposed on seinn#639: remove the override.
metadata:
  type: project
---
On 2026-09-27, seinn's `media-manager` probe failures (800ms budget) were traced to ~1s DNS stalls resolving `ceol.l42.eu`, not to media_manager (JVM pause max 23.8ms), the router, TCP (TCPSynRetrans 0) or TLS (max 28ms). Raising the budget to 2000ms was REJECTED by lucas42: 800ms sits under monitoring's 1s /_info timeout. lucas42/lucos_media_seinn#639 was rescoped to removing the 8.8.8.8 override. The alert amplification is lucas42/lucos_monitoring#303.

**Why:** containers use 127.0.0.11 (Docker DNS), which forwards to avalon's upstreams 8.8.8.8 + 213.186.33.99 with no local cache. Google was directly seen answering in ~1,028ms (c-ares, one attempt, so not packet loss). Our authoritative servers never exceeded 14ms. `RES_OPTIONS=single-request` didn't help, which rules out glibc's parallel A/AAAA race.

**How to apply:**
- A sub-1s probe failing at exactly its budget, with the request **absent from the router access log**, means a DNS/TCP/TLS phase stall. Time the phases with a Node script via `docker exec -i <c> node -` (dns.lookup, net.connect, tls.connect).
- avalon has **no `dig`**. Use Node's `dns.Resolver` with `setServers` for per-server queries. [[pattern-probe-measures-then-discards-latency]]
- Loganne `since=today` caps at ~N events **from the start of the day**, so the newest events are missing. For recent state changes, read `docker logs lucos_monitoring | grep "state changed"`.
- Unverified: monitoring's rotating single-reading `fetch-info` timeouts may be the same stalls.

**Root of the path (confirmed 2026-09-27):** `/etc/systemd/resolved.conf` has `DNS=8.8.8.8` (written 09-16 00:35Z, mid-rebuild, not in the lucos#296 runbook). The pre-rebuild netplan (rescued in `xwing:~lucos-agent/emergency-backups-2026-09-14/rescue/avalon-host-config…tar.gz`) used only OVH: 213.186.33.99 via DHCP plus 2001:41d0:3:163::1. Each container's `/etc/resolv.conf` records its upstream list in a comment (`# ExtServers: [...]`), fixed when the container is created. Head-to-head: Google 4/1,200 at ~1s vs OVH 0/1,200. The step-up came on 09-25, not 09-16; nothing changed on avalon then.
