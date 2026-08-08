---
name: pattern-duplicate-ula-subnet-blocks-network-recreate
description: "Docker 'invalid pool request: Pool overlaps with other one on this address space' on compose deploy = two repos declare the same fd00:*::/64; the network is deleted and cannot be recreated, so the service is left with NO container. Latent until a network is recreated."
metadata:
  type: project
---

`docker compose up` failing with **`failed to create network X_default: Error response from daemon: invalid pool request: Pool overlaps with other one on this address space`** means an **IPv6 ULA subnet collision**, not IPv4 pool exhaustion. The deploy deletes/loses the old network and creates no container — the service ends up **absent from `docker ps` entirely**, not crash-looping.

**Why:** ULA subnets (`fd00:N::/64`) are declared per-repo in each `docker-compose.yml` with **no central registry and no cross-repo check** — unlike volume names (`lucos_configy/config/volumes.yaml`) and hosts/domains (`hosts.yaml`, `systems.yaml`). Two repos three weeks apart picked `fd00:2::/64`; neither review could see the other. 2026-08-08: `lucos_time` down 10h52m (lucas42/lucos_time#351, fix #352 → `fd00:4::/64`). Report: `lucos/docs/incidents/2026-08-08-time-ipv6-subnet-collision.md`.

**How to apply:**

1. **Discriminate fast.** `docker network create <throwaway>` on the host — if it allocates (e.g. `172.16.8.0/24`), the IPv4 pool is fine and the overlap is IPv6. One command.
2. **Enumerate before picking a replacement.** `gh search/code "org:lucas42 fd00 in:file filename:docker-compose.yml"` gives the declarations; `docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}'` over each host gives what's live. **Declared ≠ live** — see [[compose-reuses-stale-network]] and lucas42/lucos#279.
3. **Change the DOWN service, not the holder.** Precedence (who declared first) is the wrong tiebreak: recreating the holder's network means a deliberate outage of a service that is currently working. In 2026-08-08 the holder was `lucos_dns` — recreating it would have taken estate DNS down.
4. **The collision is latent while [[compose-reuses-stale-network]] is in play.** A stale IPv4-only network never contends for the ULA subnet, so the conflict produces no symptom until someone recreates it — i.e. the lucas42/lucos#279 remediation is what *detonates* it. **Before deleting any network as #279 remediation, check its declared subnet against every other repo's.**

Known state 2026-08-08 (snapshot, re-probe): avalon `fd00:2::/64` lucos_dns · `fd00:3::/64` lucos_backups · `fd00:4::/64` lucos_time · `fd00:1::/64` declared by lucos_monitoring but **not yet live**. xwing: no `fd00:*` at all, though `lucos_dns_secondary` declares `fd00:3::/64`. Still to recreate per lucas42/lucos#279: `lucos_monitoring_default`, `lucos_dns_secondary_default`.

Related: [[pattern_named_volume_shadows_image]], [[pattern_docker_live_restore_skips_network_init]].
