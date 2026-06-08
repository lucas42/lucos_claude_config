---
name: compose-reuses-stale-network
description: Docker Compose silently REUSES a pre-existing network OR named volume instead of applying changed config (enable_ipv6/subnet/IPAM, or NFS driver_opts addr=) — a correct compose can deploy stale resources
metadata:
  type: pattern
---

# Compose foot-gun: a pre-existing network OR VOLUME is reused, NOT reconciled to new config

**Applies to named VOLUMES too, not just networks** (both bit us on 2026-06-08). A redeploy reuses an existing named volume with its OLD `driver_opts` and will NOT apply changed options. Hit by lucos_backups#306's NFS-mount migration: compose correctly changed the NFS `o: "addr=aurora.local…"` → `addr=aurora.lan`, the 3 containers (lucos_private/static_media/media_import) redeployed on xwing 17:17–17:36, but `docker volume inspect` still showed `addr=aurora.local` — the pre-existing `*_medlib`/`*_public`/`*_media` volumes were reused. Mounts stayed *healthy* only because aurora.local still resolved (mDNS), so the migration goal (get off mDNS) was NOT achieved — latent. `/proc/mounts` shows only the resolved IP (192.168.8.143, same for both names) so it can't tell you the name — **`docker volume inspect <v> -f '{{.Options.o}}'` reveals the real configured addr.** Fix: stop container, `docker volume rm <v>`, redeploy (NFS data on aurora is untouched — only the local mount definition is recreated). A plain redeploy won't reconcile it.

# Compose foot-gun: a pre-existing network is reused, NOT reconciled to new config

Docker Compose creates a network only if one of that name doesn't already exist. If a network with the project's name (e.g. `<project>_default`) already exists from an earlier deploy, Compose **silently reuses it as-is** and does **NOT** apply changed network settings — `enable_ipv6`, `ipam` subnets, labels, options. The compose file can be 100% correct and you still get a stale network.

**How it bit us (2026-06-08, lucos_backups#307):** the backups bridge migration's compose correctly declared `enable_ipv6: true` + `fd00:3::/64`, but a **stale Sept-2024 `lucos_backups_default`** network (IPv4-only) was reused → deployed container had `EnableIPv6=false`, no IPv6 → backups→IPv6-only-salvare broke (`host-tracking-failures` red), even though the compose was right. Fix: `docker network rm lucos_backups_default` (after stopping the container) + recreate with `--ipv6 --subnet fd00:3::/64`, then redeploy.

**Diagnostic signature:** `docker network inspect <net> -f '{{.EnableIPv6}} {{range .IPAM.Config}}{{.Subnet}}{{end}}'` disagrees with the compose's network block. Container missing the expected IPv6 addr (`docker exec … ip -6 addr`). The compose looks correct → don't waste time re-reading it; inspect the **live network** and check its creation age.

**Remediation:** force-recreate the network — `docker compose down` (removes the project's networks if no other container attached) then `up`, OR `docker network rm <net>` + recreate, then redeploy. A plain `compose up` after editing only the network block will NOT reconcile it.

**Verification after any such network change:** confirm the live network's EnableIPv6/subnet matches compose AND test the actual dependent path (here: bridged container → salvare `[IPv6]:22`), not just that the container started. Container "running healthy" ≠ network config applied. (Ties to [[avalon-ipv6-bridging]].)
