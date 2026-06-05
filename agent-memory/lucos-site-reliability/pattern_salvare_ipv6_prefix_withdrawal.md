---
name: pattern-salvare-ipv6-prefix-withdrawal
description: lucos_backups host-tracking-failures for home hosts = ISP dropped upstream IPv6 transit (LAN v6 still healthy). NOT a backups bug, NOT a prefix withdrawal. Self-resolves when transit returns.
metadata:
  type: project
---

# Home-host backup failures = ISP lost upstream IPv6 transit (not a prefix withdrawal)

**Signature:** `lucos_backups` check `host-tracking-failures` goes red for one or more home-LAN hosts. Debug evolves: early `salvare.s.l42.eu: [Errno None] Unable to connect to port 22 on 2a01:4b00:8598:5a00:f669:f6da:e174:624b`, later `xwing.s.l42.eu / salvare.s.l42.eu / aurora.local: [Errno 110] Operation timed out`. Reads like a backups bug; it is **not**.

**VERIFIED root cause (2026-06-05 probes, corrected from an earlier wrong guess):** the home ISP stopped routing the delegated prefix `2a01:4b00:8598:5a00::/64` **upstream**, in BOTH directions, while the LAN side stays fully up. Confirmed by:
- xwing still has its global v6 (`…:ba27:ebff:fe83:e1ee/64`), RAs still arriving (default route via CPE link-local `fe80::9683:c4ff:fe49:4315`).
- xwing ↔ salvare over global v6 = 0% loss (LAN v6 healthy; salvare has NOT lost its address).
- xwing → CPE (`2a01:4b00:8598:5a00::1` and its link-local) = 0% loss.
- xwing → Cloudflare v6 (`2606:4700:4700::1111`) = 100% loss (outbound transit dead).
- avalon (OVH, public v6) → xwing global v6 AND → salvare global v6 = 100% loss (inbound transit dead).
So: **LAN IPv6 works; internet↔home IPv6 transit is dead both ways. Break is upstream of the CPE** (CPE answers on v6 but has no ISP path). Classic "WAN IPv6/PD session dropped, LAN keeps cached prefix." IPv4 (NAT) unaffected.

**Why backups breaks (and why it's all home hosts, not just salvare):** the runner is on avalon (public internet). It reaches home hosts by names with AAAA records (`xwing.s.l42.eu` dual-stack; `salvare.s.l42.eu` AAAA-only; aurora via xwing gateway). fabric/paramiko does **no Happy-Eyeballs** — it blocks on the first resolved address (often the v6) until timeout, so even xwing (which has an A record) fails. Crossing the dead internet→home v6 boundary is the common factor.

**Why nothing else breaks:** whole inbound estate is IPv4-only (service domains CNAME→`<host>.s.l42.eu`, clients use A). Deploys + docker_health use `salvare-v4`/`xwing-v4` (A-only) → green throughout. avalon's v6 is OVH, independent.

**Resolution:** automatic when the ISP restores upstream routing (user reports ~a day last time). No data at risk; backups resume next tracking run. Don't "fix" by forcing IPv4 — lucas42 explicitly doesn't want a v4-failover for this.

**ISP framing:** NOT "I have no IPv6 address" (they'll see the prefix delegated and close it). Correct: "my delegated /64 `2a01:4b00:8598:5a00::/64` is delegated and live on my LAN, but has no upstream routing — I can't reach the IPv6 internet and it can't reach me; IPv4 works. Started ~13:10 UTC 2026-06-05 after the account change. Is my IPv6 PD static or dynamic, and was it de-routed by the change?"

**Verify-status commands:** from a home host — `ip -6 addr show scope global`, `ip -6 route show default`, `ping -6 -c3 <other-home-host-v6>` (LAN, should work), `ping -6 -c3 2606:4700:4700::1111` (outbound transit, the key test). From outside (phone on mobile data / avalon) — `ping -6 <xwing-or-salvare-v6>` (inbound). traceroute6/mtr -6 not installed on xwing; tracepath6 or install mtr if hop-by-hop needed.

**Monitoring gap:** no `salvare-v6`/transit check exists; the `-v4` naming anticipates a v6 sibling never built. `host-tracking-failures` already detects the consequence (slowly, ~tracking cadence, framed as a backup failure). First diagnosed 2026-06-05 (onset ~13:10Z); a prior occurrence "a few months ago" self-resolved.
