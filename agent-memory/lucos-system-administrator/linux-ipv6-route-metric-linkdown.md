---
name: linux-ipv6-route-metric-linkdown
description: Linux kernel prefers lower-metric routes even if they are linkdown — a metric-256 linkdown route beats a metric-600 UP route
metadata:
  type: feedback
---

In Linux IPv6 routing, **metric (lower = higher priority) is evaluated before link state**. A `linkdown` route with metric 256 will be selected over an UP route with metric 600.

**Why:** Observed during salvare IPv6 incident (2026-05-23). docker0 (NO-CARRIER, linkdown) had a route for `2a01:4b00:8598:5a00::/64` at metric 256. wlan0 (UP) had the same prefix at metric 600 (assigned by SLAAC/RA). All outbound IPv6 traffic was silently routed to docker0 and dropped, including ping replies, TCP ACKs, etc.

**Symptom:** Salvare could "ping" the ISP router but only because docker0 had the router's address (`::1`) locally — the ping never left the host. All real L2 NDP solicitations for hosts in the /64 went to docker0 (linkdown → dropped → FAILED NDP entries).

**How to apply:**
- When a host has multiple routes for the same prefix, check ALL metrics before assuming a UP interface will be used
- A Docker bridge network claiming the same /64 as the host's physical interface creates exactly this trap
- `ip -6 route show` — look for unexpected linkdown routes at lower metric than the UP interface
- Fix: remove the conflicting address from the docker bridge (`sudo ip -6 addr del <addr/prefix> dev docker0`) to eliminate the linkdown route entry

**Detection command:**
```bash
ip -6 route show | awk '{print $1, $3, $5}' | sort
# Look for same prefix appearing at different metrics on different interfaces
```
