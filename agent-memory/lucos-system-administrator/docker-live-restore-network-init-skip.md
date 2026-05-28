---
name: docker-live-restore-network-init-skip
description: Docker live-restore skips ALL network initialisation (including built-in bridge/host/none) when running containers are detected on daemon startup
metadata:
  type: feedback
---

Docker 29.4.0 (and likely earlier versions) with `live-restore: true` explicitly skips network initialisation on startup when it detects running containers. The daemon emits:

> `there are running containers, updated network configuration will not take affect`

This means **built-in networks (`bridge`, `host`, `none`) are never created** in this mode — Docker assumes they were already correct before the restart and doesn't touch them.

**Why:** Confirmed during xwing outage recovery (2026-05-28, lucos#192 follow-on). Two `systemctl restart docker` calls failed to recreate built-in networks because the 5 healthy containers were present each time. Root cause found in `journalctl -u docker`.

**How to apply:**
- If `docker network ls` shows no built-in networks after a daemon restart, check whether `live-restore: true` is set AND whether containers are currently running.
- A daemon restart while containers are running will NEVER fix missing built-in networks.
- Fix procedure: `docker stop <all-containers>` (no sudo needed) → `sudo systemctl restart docker` (clean init, built-ins created) → retrigger CI deploys.
- Any procedure that flushes `/var/lib/docker/network/files/` on a host with `live-restore: true` must plan for this: either stop all containers before restart, or accept that built-ins will be missing until a container-free restart.

See also: [[docker-fixed-cidr-v6-ipam-persistence]], [[docker-daemon-restart-risk]]
