---
name: no-onhost-source-of-truth
description: lucos deployment-model property — compose files live transiently on CI runners, never on hosts; recovery from local state corruption requires CI redeploy, not on-host recreate
metadata:
  type: reference
---

The lucos deployment model has **no on-host source of truth** for compose-managed state. Compose files live transiently on CI runners in `/home/circleci/project` during deploy and are not retained on the host afterward. The host filesystem holds only the running daemon state — no compose files, no `docker network create` invocations, no source from which user-defined networks or services can be recreated locally.

**Implications:**

- Recovery from network-plane corruption (e.g. `docker network ls` empty after a flush) requires **redeploying each affected service through CI**, not `docker network create` on the host.
- A sysadmin or SRE writing a recovery runbook for any host-level Docker-state failure must treat "redeploy via CI" as the recovery path, not "recreate via local docker commands".
- If a host is wiped, the recovery path is identical to fresh provisioning: deploy every service via CI from scratch.

**Why this is deliberate (not a bug to fix):**

- CI as the sole source of truth gives reproducibility, no drift between "what's on host" vs "what CI last deployed", and a clean disaster recovery story.
- Having compose files cached on hosts would introduce sync-drift risks — a stale on-host copy could be used for recovery and silently re-introduce regressions.

**When this is load-bearing:**

- Reviewing recovery procedures or runbooks that touch Docker / network / volume state on a production host.
- Reviewing any proposal that wants to keep "operational state" on hosts (compose files, env files, generated configs). The default answer should be "no, regenerate via CI", unless there's a compelling counter-argument.
- Architectural review of disaster-recovery plans.

**Surfaced by:** 2026-05-28 xwing-network-flush incident (lucas42/lucos#192), where a daemon-state recovery that flushed `/var/lib/docker/network/files/` left containers orphaned because the user-defined networks could not be recreated locally — no host-side record of them existed.

See: [[recurring_docker_healthy_not_reachability]] (related pattern from the same incident).
