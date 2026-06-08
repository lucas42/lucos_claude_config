---
name: avalon-ipv6-bridging
description: avalon docker IPv6 facts — daemon has global fixed-cidr-v6 + NAT66; enable_ipv6 ULA bridges reach global IPv6 (salvare); monitoring/time are IPv4-only
metadata:
  type: reference
---

# avalon Docker IPv6 bridging — verified 2026-06-08 (during #307 salvare-reachability verification)

**Daemon (`/etc/docker/daemon.json` on avalon):** `"ipv6": true`, `"fixed-cidr-v6": "2001:41d0:8:dc2c::1/64"` (a **global, routable** /64 from avalon's allocation), Docker **29.3** (so `ip6tables` is ON by default even though the key isn't in daemon.json). NAT66 works.

**salvare is IPv6-ONLY reachable.** hosts.yaml: salvare has `ipv6` + `ipv4_nat: 152.37.104.10` (shared home-gateway NAT, = xwing) but **no direct ipv4**. Per lucas42 + commit bb81f37 ("salvare only available over ipv6"), reaching salvare from avalon requires IPv6. avalon host→salvare ping6 works (~15ms); host-net `lucos_backups`→salvare IPv6:22 = CONNECT_OK.

**Which avalon docker networks are enable_ipv6 (matters for who can egress IPv6):**
- `bridge` (default docker0) and `lucos_dns_default` = **EnableIPv6=true**. `lucos_dns_default` uses ULA `fd00:2::/64`; `lucos_dns_bind` (fd00:2::3) successfully **ping6's salvare's global IPv6** → proves a bridged ULA container reaches global IPv6 via docker NAT66.
- `lucos_monitoring_default` (172.22.0.0/16) and `lucos_time_default` (192.168.16.0/20) = **IPv4-ONLY, EnableIPv6=false.** So monitoring/time CANNOT do IPv6 egress. (Architect wrongly claimed on #307 these were enable_ipv6 fd00:1/2::/64 and that monitoring fetches salvare — both false; corrected.)

**Consequences:**
- **monitoring does NOT reach salvare** (IPv4-only network + salvare has no HTTP `/_info`; salvare reports OUTBOUND via schedule_tracker `salvare-v4` docker_health check). So monitoring's no-IPv6-egress is irrelevant to salvare coverage — green board accurate. See [[pattern-monitoring-coverage-http-vs-scheduled]].
- **#307 (bridge backups + `enable_ipv6` ULA `fd00:3::/64`) IS SAFE for IPv6→salvare** — verified via the lucos_dns precedent + NAT66 working + global fixed-cidr-v6. The architect's *conclusion* holds; only the *evidence* (monitoring) was wrong. Still: verify TCP→salvare from the bridged container before merge (I only proved ICMPv6 from a bridge; TCP proven only from host-net). Architect's plan already mandates this gate.
- To give a service IPv6 egress on avalon: its compose network needs `enable_ipv6: true` (ULA subnet, mirrors lucos_dns). It's per-network, NOT automatic — adding it to one service (e.g. #307 backups) does NOT give monitoring IPv6.
