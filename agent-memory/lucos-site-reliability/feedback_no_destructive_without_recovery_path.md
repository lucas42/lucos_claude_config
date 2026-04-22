---
name: No destructive remediation without a recovery path
description: Before running docker rm -f, docker system prune, or any container-record-destroying command on a stuck production container, confirm the recovery path exists and is tested
type: feedback
---

**Rule:** Do not run `docker rm -f`, `docker system prune`, `docker volume rm`, or any command that destroys container state on a production host until the recovery path is explicit and confirmed.

**Why:** On 2026-04-22 during the avalon incident, I ran `docker rm -f lucos_dns_bind` to see if it would clear the `AlreadyExists` containerd task state. It did. But the lucos estate uses transient-deploy-directory CI — docker-compose.yml files only live on `/home/circleci/project` for the duration of a CI job, and are wiped between jobs. So once the container record was gone, there was no `docker compose up` path to recreate it on-host. The image was still pulled, the sibling container's network/volume config was recoverable via inspect, but the container itself had to be fully recreated via a fresh CircleCI deploy — which was blocked because the Docker Hub rate limit window was still active and the mirror itself was in the same stuck state. This turned a recoverable outage into one needing either lucas42 to manually reconstruct a compose file on avalon, or a full recovery of the mirror first to unblock CI.

**How to apply:**

1. **Characterise across the estate before remediating on one.** If a specific container is stuck in `AlreadyExists` or a similar pattern, run the same probe against several other containers on the same host first — if the pattern is universal, you are looking at a host-level issue (e.g. orphaned containerd tasks) that wants a host-level fix (`sudo systemctl restart containerd` or `sudo ctr -n moby task delete`), not a per-container remediation.

2. **For lucos specifically, before any `docker rm`:** confirm one of these recovery paths exists:
   - A fresh CircleCI deploy for that repo will succeed (check: CI isn't currently red on that repo, and rate-limit / mirror are healthy).
   - A compose file + production .env are already available on-host or can be put there quickly.
   - The container can be recreated via `docker run` with known image + env + network + volumes (rare — usually requires rebuilding from compose).

3. **Prefer non-destructive diagnosis.** `docker inspect`, `docker logs`, `docker events`, `ctr tasks ls` (read-only) tell you most of what you need without touching state.

4. **If a destructive action is genuinely needed, get buy-in first.** Ask lucas42 (or the team lead) to make the call, since the recovery cost is paid by a human with sudo access.

5. **The broader principle:** "I wonder if X would fix it" is not enough justification to run X in production when X is irreversible. On a dev box, sure. On a production host whose deploy pattern doesn't keep compose files persistent, the rollback cost of an experiment can be very high.
