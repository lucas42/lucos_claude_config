---
name: pattern-host-daemon-mirror-never-served
description: docker.l42.eu requires basic auth on every path; host dockerd `registry-mirrors` sends no creds, so it has NEVER served a host pull (0/121 in 72h, all 3 hosts). Fallback to Docker Hub is silent and not reliable (failed a P1 hotfix deploy 2026-09-28). lucos#307.
metadata:
  type: project
---
**Host-daemon `registry-mirrors: https://docker.l42.eu` is inert on avalon, xwing and salvare.** Found 2026-09-28 in the router log: every `docker/29.x` request from host daemons gets 401 (0 of 121 served); only CircleCI clients with credentials (`buildkit`, orb `docker/28.3.0`) get 200. Cause: `lucos_docker_mirror` nginx puts `auth_basic` on `location /` (since ADR-0002, April), and dockerd has no per-mirror credentials (from memory; not checked in the moby source).

**Why it matters:** lucas42/lucos#106's April rate-limit fix never took effect; it was "verified" only via `docker info`. The silent fallback to Hub **failed once**: the lucos_photos#547 hotfix deploy at 17:00Z returned `pull access denied … no basic auth credentials`, and a re-run passed. Options are on lucas42/lucos#307 (remove the setting now; allowlist later, with security input).

**How to apply:**
- To verify a mirror, check that it **served** the host's requests (router status by user-agent), not that `docker info` lists it or that a pull succeeded. A pull succeeds via fallback either way. Same false-positive shape as [[feedback-verify-check-claim-against-underlying-store]].
- The `docker_mirror_pull_count` canary can't detect this: CI traffic keeps it above zero.
- A deploy failing at "Pull container(s) onto remote box" with an auth error on avalon: re-run first, then check #307's status.
