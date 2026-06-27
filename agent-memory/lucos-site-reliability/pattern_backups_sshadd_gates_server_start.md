---
name: pattern-backups-sshadd-gates-server-start
description: lucos_backups "container up but no HTTP" = crash-loop from ssh-add gating server start, NOT a network problem
metadata:
  type: project
---

# lucos_backups: "starts fine but no HTTP" = crash-loop, not network

**Symptom:** `docker compose up` reports "Started" but no HTTP connection to the server (local dev). Tempting to blame the recent bridged-IPv6 network change (#307, `enable_ipv6 + fd00:3::/64`).

**Root cause:** `src/scripts/startup.sh` runs with `set -e` and does `source scripts/init-agent.sh` (which runs `ssh-add -`) **before** `pipenv run python -m server`. Any `ssh-add` failure aborts startup via `set -e` → server never binds → `restart: always` crash-loops. `docker compose ps` shows `Restarting (1)`. Defeats #140's "start server immediately" intent (that only deferred the slow info-fetch).

**Why:** Today 2026-06-27, lucas42 reported this on main. Raised as lucas42/lucos_backups#354 (P2). A backup-host-auth concern sits in the status server's critical path.
**How to apply:**
- The bridge/IPv6 network is INNOCENT — proven: run `docker compose run -d --service-ports --entrypoint sh lucos_backups -c 'pipenv run python -m server'` and `curl 127.0.0.1:8027/_info` returns JSON. The `fd00:3::/64` ipam config auto-gets an IPv4 subnet too (dual-stack works, server binds `('', port)`).
- First diagnostic for any "backups up but unreachable" report: `docker ps` (look for `Restarting`) + `docker logs lucos_backups`, NOT network inspection.
- ssh-add failure triggers seen: (1) stale/corrupt local `.env` with mangled multi-line `SSH_PRIVATE_KEY` → `error in libcrypto: unsupported` → re-fetch `.env` from creds (creds value is valid `ssh-ed25519`); (2) sandbox-only: ssh-agent flaky under qemu arm64→amd64 emulation → `communication with agent failed` (ignore on real hardware).
- Reinforces [[pattern_dev_cross_service_wiring]] stale-local-.env trap: diff local `.env` vs a fresh creds fetch before blaming a key.
- Durable fix (in #354): make ssh-agent init non-fatal so `/_info` reports degraded backups instead of crash-looping. Until merged, this recurs.
