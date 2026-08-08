---
name: docker-network-recreate-and-ula-allocation
description: Docker network recreate is non-atomic (remove-then-create, no rollback); ULA subnets are a (host, subnet) allocation needing a configy registry, not a repos-only duplicate check
metadata:
  type: reference
---

# Recreating a Docker network is a destructive, non-atomic operation

Evidenced by the 2026-08-08 `lucos_time` outage (lucas42/lucos_time#351, incident report lucas42/lucos#281): the network was removed, creation failed on a subnet collision, and the service sat with **no network and no container for 10h52m**.

**The cost of a failed recreate is an unbounded outage, not a brief interruption.** My original framing on lucas42/lucos#279 ("don't auto-recreate, it stops attached containers") priced only the interruption and understated this.

**Fail-loud / require-a-human does not cover it.** In that incident the human triggered the recreate deliberately. A human approving a recreate has no better view of subnet allocatability on the target host than the orb does — arguably worse, since the orb is talking to the daemon. The control that actually works is a **precondition on the destructive step**: check-then-delete.

```
docker network create --ipv6 --subnet <declared-subnet> lucos-preflight-tmp \
  && docker network rm lucos-preflight-tmp
```

Generalise: *a human gate defends against the machine acting unprompted; it does nothing when the human is the one performing the risky action.* Ask which of the two you're actually defending against before proposing a gate.

## `lucos_deploy_orb` never removes a network

`src/commands/deploy.yml` runs `docker compose up -d --no-build --wait --wait-timeout 180` in a 3-attempt loop, plus a `docker compose stop` for `network_mode: host` services only. No `compose down`, no `network rm`. So any network deletion in the estate is **out-of-band/manual** — a deploy-time gate would sit on a path the destructive step never takes. It also PUTs `monitoring.l42.eu/suppress/$REPO` with `|| true`, so while monitoring is down every *other* service's deploy silently loses alert suppression.

Related: [[declared-vs-deployed-docker-networks]] — Compose does not retrofit changed `enable_ipv6`/IPAM onto an existing network.

# ULA subnet allocation: the key is (host, subnet)

Docker checks pool overlap **per daemon**. The same subnet on two hosts does not collide. So a `lucos_repos` duplicate-detector over compose files alone is *wrong*: it would flag `lucos_backups` `fd00:3::/64` on avalon vs `lucos_dns_secondary` `fd00:3::/64` on xwing as a conflict when it isn't. To be correct it needs the host mapping — which lives in `lucos_configy/config/systems.yaml`. Half a registry, none of the benefits.

**A ULA subnet is the same class of resource as `http_port`** — scarce, host-scoped, numeric, allocated at author time, invisible to the reviewer of any single repo. The estate already registers `http_port` centrally in `systems.yaml`. That precedent, not implementation cost, is the deciding argument (see [[scope-first-not-principal-class]] on judging modelling calls by conceptual fit).

**Estate pattern for this class: registry in `lucos_configy` + convention check in `lucos_repos` that the repo matches it.** Both halves are existing machinery — `in-lucos-configy` proves repos reads configy; `container-naming` / `standard-env-vars-in-compose` prove it parses `docker-compose.yml`. Caveat: `volumes.yaml` has **no** enforcing convention in `lucos_repos` (checked 2026-08-09), so this is the pattern to recommend, not one uniformly implemented — a registry nobody's compose file is checked against will drift.

**Do not fold allocation-conflict work into lucas42/lucos#279.** #279 is runtime divergence (declared config that never took effect; detected at deploy/runtime; homed in the orb or `lucos_docker_health`). Allocation conflict is author-time (two individually-valid declarations; detected at review; homed in configy + repos). Shared mechanism ≠ shared decision — same trap as [[new-consideration-gets-own-adr]].
