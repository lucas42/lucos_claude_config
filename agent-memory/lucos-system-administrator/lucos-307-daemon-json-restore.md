---
name: lucos-307-daemon-json-restore
description: avalon post-rebuild daemon.json missing registry-mirrors/live-restore — analysis posted, confirmed hot-reloadable, awaiting lucas42 to apply
metadata:
  type: project
---

lucas42/lucos#307 (Needs Analysis, owned by sysadmin): avalon's rebuilt `/etc/docker/daemon.json` (mtime 2026-09-15 22:28, i.e. lucas42's own Step 1 provisioning window) is missing `registry-mirrors: ["https://docker.l42.eu"]` (lucos#106) and `live-restore: true` (lucos#107). Confirmed not deliberate — no record of a decision anywhere (runbook #296 explicitly listed both for restoration; incident report doesn't mention them); matches the same "unrecorded hand-edit during rebuild" pattern as the `DNS=8.8.8.8` divergence found the same day (lucas42/lucos_media_seinn#639).

**Confirmed via Docker's own docs (2026-09-27): both settings are hot-reloadable via `systemctl reload docker` (SIGHUP), including the disabled→enabled transition for live-restore itself — no restart needed, zero container impact.** This generalizes [[docker-daemon-restart-risk]] beyond "many options are reloadable" to a verified-against-source confirmation for these two specifically. Reusable fact for any future daemon.json change on production hosts: always check the live-restore/reload docs before assuming a restart is needed.

Full analysis + exact command block (backup, edit, validate JSON, reload, verify via `docker info` + before/after `docker ps` diff) posted at https://github.com/lucas42/lucos/issues/307#issuecomment-5860583841. Target config matches the pre-rebuild rescued daemon.json exactly (verified by extracting `avalon-host-config.rescue-2026-09-14.tar.gz` on xwing) — plain `https://docker.l42.eu` mirror URL, not the untested `localhost:8038` alternative #106 speculated about (mirror confirmed healthy/reachable from avalon itself).

Needs root — lucas-agent has no passwordless sudo on avalon, so lucas42 applies it. Follow-up once done: lucas42/lucos#300 (merged host-setup runbook) should carry both settings so the next rebuild doesn't drop them again.
