---
name: pattern-host-daemon-mirror-never-served
description: docker.l42.eu requires basic auth on every path; host dockerd `registry-mirrors` sends no creds, so it serves no host pulls (0/121 in 72h: avalon + xwing; salvare unobserved). Fallback to Docker Hub is silent and not reliable (failed a P1 hotfix deploy 2026-09-28). lucos#307.
metadata:
  type: project
---
**Host-daemon `registry-mirrors: https://docker.l42.eu` is inert on avalon and xwing** (salvare unobserved: no daemon requests in the window). xwing was never rebuilt, so it isn't rebuild drift. Found 2026-09-28 in the router log: every `docker/29.x` request from host daemons gets 401 (0 of 121 served). Attribute them by UA **version** (avalon 29.8.1 since 09-15; xwing 29.4.0 until 09-27), because the router shows every avalon-local and IPv6 client as 172.16.5.1; only CircleCI clients with credentials (`buildkit`, orb `docker/28.3.0`) get 200. Cause: `lucos_docker_mirror` nginx puts `auth_basic` on `location /` (since ADR-0002, April), and dockerd has no per-mirror credentials (from memory; not checked in the moby source).

**Why it matters:** lucas42/lucos#106's April rate-limit fix most likely never took effect (the 72h log can't prove the April–Sept period); it was "verified" only via `docker info`. The silent fallback to Hub **failed once**: the lucos_photos#547 hotfix deploy at 17:00Z returned `pull access denied … no basic auth credentials`, and a re-run passed. Options are on lucas42/lucos#307 (remove the setting now; allowlist later, with security input).

**How to apply:**
- To verify a mirror, check that it **served** the host's requests (router status by user-agent), not that `docker info` lists it or that a pull succeeded. A pull succeeds via fallback either way. Same false-positive shape as [[feedback-verify-check-claim-against-underlying-store]].
- The `docker_mirror_pull_count` canary can't detect this: CI traffic keeps it above zero.
- A deploy failing at "Pull container(s) onto remote box" with an auth error on avalon: re-run first, then check #307's status.

**Update 2026-09-28 (lucos-security read the source issue directly):** moby/moby issue 30880, open since 2017: dockerd ignores `docker login` credentials for pulls through `registry-mirrors` ("no basic auth credentials"). So a host daemon **can't** authenticate to an auth-gated mirror. Option 1 (remove the setting) is effectively the end state. Any "make the mirror serve hosts" design goes to lucos-security before it ships; two "safe" designs have already failed.

**⚠️ Never allowlist by IP at avalon's router:** every IPv6 client, from anywhere, reaches the router as **172.16.5.1** (the router is IPv4-only; IPv6 arrivals are re-originated over IPv4). That's the same address as avalon's own containers and as xwing/salvare over IPv6. Seen in the router log: Facebook's crawler, ~23k `Mozilla` requests, and the remote linuxplayers, all from 172.16.5.1. `X-Real-IP` is collapsed before nginx ever sets it.
