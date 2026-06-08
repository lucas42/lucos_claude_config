---
name: compose-reuses-stale-network
description: Docker Compose silently REUSES a pre-existing network instead of applying changed enable_ipv6/subnet/IPAM config — a correct compose can deploy a stale network
metadata:
  type: pattern
---

# Compose foot-gun: a pre-existing network is reused, NOT reconciled to new config

Docker Compose creates a network only if one of that name doesn't already exist. If a network with the project's name (e.g. `<project>_default`) already exists from an earlier deploy, Compose **silently reuses it as-is** and does **NOT** apply changed network settings — `enable_ipv6`, `ipam` subnets, labels, options. The compose file can be 100% correct and you still get a stale network.

**How it bit us (2026-06-08, lucos_backups#307):** the backups bridge migration's compose correctly declared `enable_ipv6: true` + `fd00:3::/64`, but a **stale Sept-2024 `lucos_backups_default`** network (IPv4-only) was reused → deployed container had `EnableIPv6=false`, no IPv6 → backups→IPv6-only-salvare broke (`host-tracking-failures` red), even though the compose was right. Fix: `docker network rm lucos_backups_default` (after stopping the container) + recreate with `--ipv6 --subnet fd00:3::/64`, then redeploy.

**Diagnostic signature:** `docker network inspect <net> -f '{{.EnableIPv6}} {{range .IPAM.Config}}{{.Subnet}}{{end}}'` disagrees with the compose's network block. Container missing the expected IPv6 addr (`docker exec … ip -6 addr`). The compose looks correct → don't waste time re-reading it; inspect the **live network** and check its creation age.

**Remediation:** force-recreate the network — `docker compose down` (removes the project's networks if no other container attached) then `up`, OR `docker network rm <net>` + recreate, then redeploy. A plain `compose up` after editing only the network block will NOT reconcile it.

**Verification after any such network change:** confirm the live network's EnableIPv6/subnet matches compose AND test the actual dependent path (here: bridged container → salvare `[IPv6]:22`), not just that the container started. Container "running healthy" ≠ network config applied. (Ties to [[avalon-ipv6-bridging]].)
