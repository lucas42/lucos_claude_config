---
name: Docker daemon restart risk — live-restore and hot-reload
description: Restarting docker daemon without live-restore kills all containers; many daemon.json changes can be applied via SIGHUP instead
type: feedback
---

**Never recommend or script `systemctl restart docker` on production without first checking:**

1. Is `live-restore: true` set in daemon.json? If not, the restart will SIGKILL every running container. Those with `restart: always` come back; the rest are left with orphaned containerd tasks that block subsequent `docker start` — recovery requires `sudo systemctl restart containerd && sudo systemctl restart docker`.

2. Does the daemon.json change actually require a full restart? Many options support hot-reload via `systemctl reload docker` (sends SIGHUP) — including `live-restore`, `registry-mirrors`, `labels`, `debug`, `insecure-registries`. SIGHUP applies config changes without touching running containers.

**The right order for daemon.json changes:**

1. Check `docker info | grep -i 'live restore'` — if `false`, a restart will be destructive.
2. If the change is hot-reloadable, use `systemctl reload docker` (SIGHUP). Verify with `docker info` after.
3. If a full restart is unavoidable and live-restore is disabled, warn the operator explicitly: "this will kill all running containers".

**Why:** The 2026-04-22 incident. We added `registry-mirrors` to daemon.json on avalon and recommended `systemctl restart docker`. Live-restore was disabled. ~40 containers were killed; containerd orphan tasks blocked restart; `lucos_dns_bind` went down and the entire `l42.eu` DNS zone SERVFAILed at public resolvers for ~45 minutes. `registry-mirrors` is hot-reloadable — the restart was unnecessary.

**How to apply:** Before writing daemon.json change runbooks or issue comments, include the SIGHUP approach if the changed options are hot-reloadable. Add explicit live-restore check if a restart is unavoidable.
