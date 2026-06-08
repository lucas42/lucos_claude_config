---
name: docker-29x-chains
description: "Docker 29.x adds DOCKER-CT and DOCKER-BRIDGE chains (in addition to earlier DOCKER-FORWARD) — all six must exist for docker network create to succeed"
metadata:
  type: reference
---

Docker 29.x (tested on 29.3.0) requires six chains in the iptables/ip6tables filter table for `docker network create` to succeed:

1. `DOCKER-FORWARD` — per-network interface ACCEPT rules
2. `DOCKER-BRIDGE` — bridge-to-Docker jump rules  
3. `DOCKER-CT` — conntrack RELATED,ESTABLISHED rules per bridge
4. `DOCKER-ISOLATION-STAGE-1` — inter-network isolation stage 1
5. `DOCKER-ISOLATION-STAGE-2` — inter-network isolation stage 2
6. `DOCKER` — published port ACCEPT rules

All six needed in FORWARD chain (plus DOCKER-USER at position 1):
```
1. DOCKER-USER (security — must be first)
2. DOCKER-ISOLATION-STAGE-1
3. DOCKER-FORWARD
4. DOCKER-CT
5. DOCKER-BRIDGE
```

DOCKER-ISOLATION chains need initial rules:
```bash
iptables -A DOCKER-ISOLATION-STAGE-1 -j RETURN
iptables -A DOCKER-ISOLATION-STAGE-2 -j DROP
```

**Recovery procedure** (when chains missing due to old whole-table restore):
```bash
docker exec lucos_firewall /bin/sh -c "
for chain in DOCKER DOCKER-BRIDGE DOCKER-CT DOCKER-FORWARD DOCKER-ISOLATION-STAGE-1 DOCKER-ISOLATION-STAGE-2; do
    /usr/sbin/iptables -N \$chain 2>/dev/null
    /usr/sbin/ip6tables -N \$chain 2>/dev/null
done
/usr/sbin/iptables -A DOCKER-ISOLATION-STAGE-1 -j RETURN
/usr/sbin/iptables -A DOCKER-ISOLATION-STAGE-2 -j DROP
/usr/sbin/ip6tables -A DOCKER-ISOLATION-STAGE-1 -j RETURN
/usr/sbin/ip6tables -A DOCKER-ISOLATION-STAGE-2 -j DROP
for table_cmd in iptables ip6tables; do
    /usr/sbin/\$table_cmd -A FORWARD -j DOCKER-ISOLATION-STAGE-1
    /usr/sbin/\$table_cmd -A FORWARD -j DOCKER-FORWARD
    /usr/sbin/\$table_cmd -A FORWARD -j DOCKER-CT
    /usr/sbin/\$table_cmd -A FORWARD -j DOCKER-BRIDGE
done
"
```

**Why:** These chains are created by Docker daemon at startup and maintained by Docker. lucos_firewall v1.0.9 and earlier used whole-table iptables-restore (no --noflush) which wiped all user-defined chains not declared in the ruleset. v1.0.10+ uses --noflush so these chains are preserved.

**Note:** With `live-restore: true` and containers running, a Docker daemon restart does NOT re-create these chains (Docker skips network init). Manual recovery procedure above is needed. See [[docker-live-restore-network-init-skip]].

**Confirmed on:** avalon (2026-06-08) during lucos_firewall#19 resolution.
