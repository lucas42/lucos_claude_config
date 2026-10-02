---
name: pattern-docker-socket-bind-stale-after-daemon-restart
description: lucos_docker_health "Cannot connect to the Docker daemon" on a host = dockerd restarted (unattended docker-ce upgrade) under live-restore, leaving the file bind mount of docker.sock on a dead inode; fix is docker restart of the container
metadata:
  type: project
---

`lucos_docker_health/<host>` red with `Failed to list containers: Cannot connect to the Docker daemon at unix:///var/run/docker.sock` while the container shows `Up … (healthy)` = the host's dockerd restarted after the container started. The usual trigger is `unattended-upgrade` bumping `docker-ce`; check `/var/log/apt/history.log` and `systemctl show docker -p ActiveEnterTimestamp`. Because of `live-restore: true` the container survives, but its **file** bind mount of `/var/run/docker.sock` pins the deleted inode.

**Why:** found 2026-10-01/02 on avalon (17h blind) and salvare (12.5h). The heartbeat-age healthcheck keeps it "healthy", so nothing self-heals. Recurrence fix is tracked in lucas42/lucos_docker_health#124 (exit after N consecutive connection errors so `restart: always` remounts).

**How to apply:** quick test is to compare `stat -c %z /var/run/docker.sock` against the container's StartedAt. The container has no shell (scratch image), so you can't stat the socket inside it. Fix = loganne plannedMaintenance, `PUT /suppress/lucos_docker_health`, then `docker restart lucos_docker_health_app` one host at a time. The all-clear is held until the manual window expires (~10 min), which logs a benign `expired without being cleared` error. Any other container that bind-mounts docker.sock is presumably exposed to the same thing (I haven't checked which ones do). Related: [[pattern_docker_live_restore_skips_network_init]].
