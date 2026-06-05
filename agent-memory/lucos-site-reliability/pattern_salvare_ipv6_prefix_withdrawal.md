---
name: pattern-salvare-ipv6-prefix-withdrawal
description: lucos_backups host-tracking-failures for salvare = home ISP withdrew the IPv6 /64, NOT a backups bug. Self-resolves when prefix returns.
metadata:
  type: project
---

# salvare backup failure = home IPv6 prefix withdrawal (ISP)

**Signature:** `lucos_backups` check `host-tracking-failures` (and sometimes `volume-host`) goes red, debug = `salvare.s.l42.eu: [Errno None] Unable to connect to port 22 on 2a01:4b00:8598:5a00:f669:f6da:e174:624b`. Reads like a backups bug; it is **not**.

**Root cause:** salvare is the only host with **no IPv4 of its own** (`ipv4: null`, NAT-shared `152.37.104.10` via xwing). Its only reachable address is the global IPv6 under the home delegated prefix `2a01:4b00:8598:5a00::/64`. When the ISP withdraws/changes that prefix delegation (e.g. after an account/"bureaucracy" change), salvare's IPv6 stops being routable — even its LAN neighbour xwing can't reach it on that global address.

**Why only backups breaks (blast radius = 1):**
- `salvare.s.l42.eu` is **AAAA-only** (IPv6) in lucos_dns. Backups connects via this name (ProxyJump through xwing) → forced onto the dead IPv6.
- Deploys + docker_health use **`salvare-v4.s.l42.eu`** (A-only, `152.37.104.10`) → unaffected. This is why `docker_health/salvare-v4` stays green through the outage.
- The whole inbound estate is **IPv4-only** (service domains CNAME → `<host>.s.l42.eu`; clients use A records). No user-facing path touches IPv6.
- avalon's IPv6 is OVH (`2001:41d0:8:dc2c::1`), independent of the home ISP.

**Resolution:** automatic when the ISP restores the prefix (user reports ~a day). No data at risk — salvare's volumes are intact; backups resume on the next tracking run. Don't "fix" by forcing IPv4: salvare has no inbound IPv4, and lucas42 explicitly does **not** want a v4-failover for this.

**Caveats (unverified):** salvare's IID `f669:f6da:e174:624b` is random/stable-privacy (no `ff:fe` → not EUI-64), so a genuine prefix *reassignment* could change the full address, leaving the static AAAA in lucos_dns stale even after IPv6 returns. Worth checking the AAAA still matches once the ISP restores service.

**Monitoring gap:** there is no `salvare-v6` liveness check — the `-v4` naming convention anticipates a v6 sibling that was never built. `host-tracking-failures` already detects the consequence (just slowly, ~daily/hourly tracking cadence, and framed as a backup failure). First diagnosed 2026-06-05 (outage onset ~13:10Z); a prior occurrence "a few months ago" self-resolved.
