---
name: pattern-docker-live-restore-skips-network-init
description: Docker 29.4.0 with `live-restore: true` skips ALL network initialisation (including built-in bridge/host/none) when running containers are present at daemon start. Recovery requires `docker stop` of all containers before the daemon restart.
metadata:
  type: project
---

When `live-restore: true` is set and Docker is restarted with running containers present, the daemon emits this log line on startup:

> `there are running containers, updated network configuration will not take affect`

It then **skips all network initialisation**, including the built-in `bridge`/`host`/`none` networks. This is deliberate Docker behaviour to avoid disrupting live-restored workloads — but the consequence is that if those built-ins are *missing* (e.g. after the daemon's network DB was previously corrupted), a daemon restart will **not** recreate them as long as containers are running.

## How to recognise it

- `docker network ls` returns a list missing one or more of `bridge`/`host`/`none`
- `sudo systemctl restart docker` runs successfully but leaves the situation unchanged
- Containers using `network_mode: host` fail to deploy with `network host not found`
- `docker network create host` (or `bridge` / `none`) is blocked with "reserved name"
- Daemon logs (`journalctl -u docker` — needs sudo) contain the `there are running containers` warning

## The fix

Short-circuit the live-restore protection by removing what it's protecting:

1. `docker stop $(docker ps -q)` — does NOT require sudo; affects the current daemon socket
2. `sudo systemctl restart docker` — with zero running containers, daemon initialises fully: built-ins created, `docker0` rebuilt with whatever IPv6 IPAM is configured in `daemon.json`
3. Redeploy all the services via CircleCI so compose files recreate the user-defined networks (no on-host source of truth)

This produces a deliberate brief total outage on the host (typically ~1 minute) but is the only clean recovery shape. Send a `plannedMaintenance` Loganne event before step 1.

## Why "just restart docker" is the wrong first hypothesis

It looks like the right hypothesis. If the built-in networks are missing, the obvious thing is to restart the daemon and let it re-init. That fails silently under `live-restore: true` — `docker network ls` looks the same after the "successful" restart as it did before. Without daemon log access (sudo required), the failure mode is invisible.

If you find yourself diagnosing missing built-in networks and the first `sudo systemctl restart docker` didn't fix it, the next step is `journalctl -u docker | tail` (sudo) — not progressively more aggressive restart variants.

## Provenance

[[pattern_three_stage_env_var_wiring]] is the prior "the obvious recovery doesn't work; check daemon-internal mechanism" pattern. This one is the docker-daemon equivalent. The 2026-05-28 xwing incident report (`docs/incidents/2026-05-28-xwing-network-flush-orphaned-containers.md`, Stage 5) is the canonical record; this memory captures the load-bearing pattern for future investigations.

Related: [[feedback_healthcheck_depth_varies]] — the docker-state corruption that triggered the recovery is invisible to container-internal healthchecks (`Healthy` survives while containers are orphaned from their network).
