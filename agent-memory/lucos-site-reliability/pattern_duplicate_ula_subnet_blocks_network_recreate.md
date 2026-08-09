---
name: pattern-duplicate-ula-subnet-blocks-network-recreate
description: "Docker 'invalid pool request: Pool overlaps with other one on this address space' on compose deploy = two repos declare the same fd00:*::/64; the network is deleted and cannot be recreated, so the service is left with NO container. Latent until a network is recreated."
metadata:
  type: project
---

`docker compose up` failing with **`failed to create network X_default: Error response from daemon: invalid pool request: Pool overlaps with other one on this address space`** means an **IPv6 ULA subnet collision**, not IPv4 pool exhaustion. The deploy deletes/loses the old network and creates no container — the service ends up **absent from `docker ps` entirely**, not crash-looping.

**Why:** ULA subnets (`fd00:N::/64`) are declared per-repo in each `docker-compose.yml` with **no central registry and no cross-repo check** — unlike volume names (`lucos_configy/config/volumes.yaml`) and hosts/domains (`hosts.yaml`, `systems.yaml`). Two repos three weeks apart picked `fd00:2::/64`; neither review could see the other. 2026-08-08: `lucos_time` down 10h52m (lucas42/lucos_time#351, fix #352 → `fd00:4::/64`). Report: `lucos/docs/incidents/2026-08-08-time-ipv6-subnet-collision.md`.

**How to apply:**

0. **`lucos_deploy_orb` NEVER removes a network** (verified 2026-08-08, `src/commands/deploy.yml` on `origin/main`: no `network rm`, no `compose down`, no `network prune` — only `compose stop` for `network_mode: host` services and `image prune -f`). So a deploy log showing Compose in **`Network X_default  Creating`** proves the network was removed **out of band before the pipeline ran** — Compose only enters `Creating` for an absent network. ⚠️ You **cannot** date the removal from avalon's docker journal: agents have **no sudo** there, and `journalctl -u docker` returns *empty output* on the password prompt, which reads exactly like "no event found". Best-fit hypothesis for a vanished container **and** network together is a manual `docker compose down` (a bare `network rm` fails with a container attached).
1. **Discriminate fast.** `docker network create <throwaway>` on the host — if it allocates (e.g. `172.16.8.0/24`), the IPv4 pool is fine and the overlap is IPv6. One command.
2. **Enumerate before picking a replacement.** `gh search/code "org:lucas42 fd00 in:file filename:docker-compose.yml"` gives the declarations; `docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}'` over each host gives what's live. **Declared ≠ live** — see [[compose-reuses-stale-network]] and lucas42/lucos#279.
3. **Change the DOWN service, not the holder.** Precedence (who declared first) is the wrong tiebreak: recreating the holder's network means a deliberate outage of a service that is currently working. In 2026-08-08 the holder was `lucos_dns` — recreating it would have taken estate DNS down.
4. **The collision is latent while [[compose-reuses-stale-network]] is in play.** A stale IPv4-only network never contends for the ULA subnet, so the conflict produces no symptom until someone recreates it — i.e. the lucas42/lucos#279 remediation is what *detonates* it. **Before deleting any network as #279 remediation, check its declared subnet against every other repo's.**

**A network recreate is NON-ATOMIC WITH NO ROLLBACK** — remove, then create; if create fails you have neither, and the outage is unbounded rather than brief. A "require a human" gate does **not** fix this (a human triggered the lucos_time one deliberately, with no better view of allocatability than the orb). Two controls, both cheap, both needed: **(a)** precondition probe before the destructive step — `docker network create --ipv6 --subnet <declared> tmp && docker network rm tmp` (also tests the IPv4 pool; ⚠️ false-fails if the target network already holds its own declared subnet, so never generalise to "delete first, then probe"); **(b)** `docker network inspect -f '{{json .IPAM.Config}} {{.EnableIPv6}}'` **recorded off-shell before removal**, so a failed create can be restored. ⚠️ **The restore command is NOT a bare `docker network create --subnet …`** — compose refuses to adopt an unlabelled network and exits 1 (verified 2026-08-08: compose nets carry `com.docker.compose.network` / `.project` / `.version`; a bare create yields `{}`). Working form:
```
docker network create --subnet <recorded> \
  --label com.docker.compose.network=default \
  --label com.docker.compose.project=<project> \
  <project>_default
```
⚠️ Probe (a) **false-fails if the target already holds its own declared subnet** — so **inspect first, then branch**: already holds it ⇒ not divergent, do not touch; divergent (no IPv6 / different subnet) ⇒ probe is valid. Never "delete first, then probe". (a) bounds probability; only (b) bounds consequence.

⚠️ **After ANY recreate, expect ~4 min of settling — do NOT measure inside it.** A container restarting onto a new network shows wild latency (NDP/NAT66/route learning), and monitoring restarting re-warms its whole cache: 2026-08-08, **52 systems** logged `Warm-up: skipping alert` within 6s, presenting as 19 "buffering" + a self-poll timing out. I read that as a permanent regression, filed a P2 and messaged two teammates; it cleared on its own. Verify immediately only what is immediately true (container healthy, network matches declaration), then leave behavioural probes until it settles and **measure twice with a gap**. An immediate dual-stack probe here would have argued for rolling back a correct change.

⚠️ Recreating `lucos_monitoring_default` is the worst case: the orb's `PUT monitoring.l42.eu/suppress/$REPO` is `|| true`, so while monitoring is down **every other service's deploy silently loses alert suppression** — and a quiet dashboard is not health. Confirm from off-avalon.

Known state 2026-08-08 (snapshot, re-probe): avalon `fd00:2::/64` lucos_dns · `fd00:3::/64` lucos_backups · `fd00:4::/64` lucos_time · `fd00:1::/64` declared by lucos_monitoring but **not yet live**. xwing: no `fd00:*` at all, though `lucos_dns_secondary` declares `fd00:3::/64`. Still to recreate per lucas42/lucos#279: `lucos_monitoring_default`, `lucos_dns_secondary_default`.

Related: [[pattern_named_volume_shadows_image]], [[pattern_docker_live_restore_skips_network_init]].
