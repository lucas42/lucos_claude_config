---
name: pattern-firewall-rollback-wipes-docker-nat
description: "TLS completes then hang + router 'upstream timed out while connecting to 172.17.0.1:<port>' + host-local 200 = Docker DNAT missing; lucos_firewall full-table revert loop re-imposes it (2026-11-25, 35h outage, lucos_firewall#31)"
metadata:
  type: project
---

Signature (2026-11-25 → 26, ~35h47m estate outage): TLS to avalon completes quickly, then no bytes arrive. lucos_router logs `upstream timed out (110) while connecting to upstream` for EVERY backend at `172.17.0.1:<port>`. curl from the avalon host to 127.0.0.1/172.17.0.1:<port> returns 200. lucos_firewall logs loop "Applying fallback ruleset … Auto-reverting to previous ruleset … Rules NOT confirmed" every ~2 min.

Mechanism: `docker exec lucos_firewall iptables-save -t nat | grep -c DNAT` = 0 against N published ports. lucos_firewall's `applyWithRollback` snapshots ALL tables and reverts with full (non-`--noflush`) restore, so it re-imposes a mid-dockerd-restart nat table forever. configy (its confirmation target) sits behind the router, so it can never confirm. The trigger was an unattended docker-ce upgrade restarting dockerd; the firewall's snapshot came 12s later on avalon (xwing: 2m42s later, NAT survived).

**Why:** a rollback that restores state it doesn't own, plus a confirmation check behind the thing it breaks, gives a loop with no exit.

**How to apply:**
- Fix order: (1) freeze the firewall (`DRY_RUN=true` one-off `docker compose -p lucos_firewall up -d --no-build --pull never`). DRY_RUN alone does NOT repair anything; dry-run never touches iptables. (2) `systemctl restart docker` (lucas42; no agent sudo) re-creates DNAT. (3) Revert via CircleCI redeploy.
- ⚠️ The firewall has NO signal handling: stopping it inside a "Rules applied — waiting 30s" window leaves the fallback live with nothing to revert. Gate any stop/recreate on a "Rules NOT confirmed" line. `grep -m1` in a `docker logs -f` pipe only returns on the NEXT log line (SIGPIPE), which is ~70s later.
- Read iptables without sudo via `docker exec lucos_firewall iptables-save` (host netns, NET_ADMIN).
- Alerting was blind for the whole outage: 267 notifications, 0 delivered (lucos#334; accepted risk lucos#295). Don't expect an alert for this class.
