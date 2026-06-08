---
name: docker-compose-stale-network
description: "Docker compose will reuse an existing named network even if its config (enable_ipv6, subnet) has changed — must manually recreate to pick up changes"
metadata:
  type: reference
---

Docker compose checks for a network by name. If the name exists, compose **reuses it** regardless of config drift (different subnet, IPv6 toggle, etc). It does NOT recreate or update an existing network.

**Triggered by:** lucos_backups#307 — compose change added `enable_ipv6: true` + `fd00:3::/64`, but `lucos_backups_default` existed from 2024-09-29 (IPv4-only). Container deployed on the stale network, salvare unreachable.

**Detection:** `docker network inspect <project>_default --format "EnableIPv6: {{.EnableIPv6}}, Created: {{.Created}}"` — check Created date and IPv6 status against what compose expects.

**Fix procedure:**
1. Check no active jobs are running (read container logs)
2. `docker stop <container>`
3. `docker network rm <project>_default`
4. Create new network manually with correct config + compose labels:
   ```bash
   docker network create --driver bridge --ipv6 --subnet <subnet> \
     --label com.docker.compose.network=default \
     --label com.docker.compose.project=<project> \
     <project>_default
   ```
5. If container was stopped (not removed): the stopped container has the OLD network ID wired in — `docker start` will fail. Must `docker rm <container>` and redeploy via CI trigger commit.
6. Push empty CI trigger commit → compose creates container fresh on new network.

**Also applies to:** `lucos_monitoring_default`, `lucos_time_default` — both have `enable_ipv6: true` declared in compose but live networks are IPv4-only (never recreated). Not currently causing issues since neither needs IPv6 to reach its targets.

**Confirmed on:** avalon (2026-06-08) during lucos_backups#307.
