---
name: xwing/salvare IPv6 accept_ra fix
description: xwing/salvare IPv6 loss — check what the router advertises first; NM-managed since 2026-09-27 so accept_ra=0 is normal
type: project
---

## accept_ra=2 applied to xwing and salvare (2026-04-19/20)

Both hosts now have `net.ipv6.conf.eth0.accept_ra = 2` in `/etc/sysctl.conf` (xwing: eth0, salvare: wlan0 — check interface name if re-applying).

**Why:** Docker enables IPv6 forwarding (`net.ipv6.conf.*.forwarding=1`), which silently sets `accept_ra=0`. This means Linux ignores Router Advertisements from the home router and cannot auto-configure new IPv6 addresses when the prefix changes. The fix (`accept_ra=2`) allows RA acceptance even with forwarding on — standard pattern for Docker hosts with IPv6.

**Incident summary (2026-04-19):** Home router lost its DHCPv6 prefix delegation state — it deprecated the old prefix but stopped sending RAs entirely (not an ISP rotation as initially thought). Valid_lft ticking down without refreshing = router sending no RAs at all. Router restart recovered the same prefix; no DNS changes were needed.

**How to apply:** If it recurs on a future prefix rotation:
1. `ip -6 addr show scope global` on xwing — if no non-deprecated address, check `cat /proc/sys/net/ipv6/conf/eth0/accept_ra`
2. If accept_ra is not 2, the fix has been lost from sysctl
3. Re-apply: `echo 2 > /proc/sys/net/ipv6/conf/eth0/accept_ra` + add to `/etc/sysctl.conf`
4. Wait for next RA (up to ~10 min), then update `lucos_configy/config/hosts.yaml` with new addresses
5. DNS sync runs every 15 min and picks up automatically

**Diagnostic: valid_lft ticking down at 1s/s** means the router is sending NO RAs at all (not even for the old prefix) — router restart needed, not just a wait.

**SSH to salvare** (no A record, only AAAA): use `ssh -o ProxyJump=xwing.s.l42.eu -o "HostName <ipv6>" lucos-agent@salvare.s.l42.eu` when DNS is broken.

## Update 2026-11-03: hosts are NetworkManager-managed — `accept_ra=0` is normal, not the fault

Since the 2026-09-27 boot both hosts use NM (`ipv6.method: auto`), which processes RAs itself; kernel `accept_ra` reads 0 and `/etc/sysctl.conf`'s 2 is overridden. Steps 2-3 above no longer apply. First check what the router advertises: `docker run --rm --net=host --cap-drop=ALL --cap-add=NET_RAW alpine sh -c "apk add -q ndisc6; rdisc6 -1 eth0"` (no root needed; agent is in the docker group). A RA with router lifetime 0 and no prefix option = router has no IPv6 upstream (lucos#331). salvare's eth0 has had no carrier since boot; it runs on wlan0.
