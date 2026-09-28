---
name: lucos-307-daemon-json-restore
description: avalon post-rebuild daemon.json missing registry-mirrors/live-restore — analysis posted, confirmed hot-reloadable, awaiting lucas42 to apply
metadata:
  type: project
---

lucas42/lucos#307 (Needs Analysis, owned by sysadmin): avalon's rebuilt `/etc/docker/daemon.json` (mtime 2026-09-15 22:28, i.e. lucas42's own Step 1 provisioning window) is missing `registry-mirrors: ["https://docker.l42.eu"]` (lucos#106) and `live-restore: true` (lucos#107). Confirmed not deliberate — no record of a decision anywhere (runbook #296 explicitly listed both for restoration; incident report doesn't mention them); matches the same "unrecorded hand-edit during rebuild" pattern as the `DNS=8.8.8.8` divergence found the same day (lucas42/lucos_media_seinn#639).

**Confirmed via Docker's own docs (2026-09-27): both settings are hot-reloadable via `systemctl reload docker` (SIGHUP), including the disabled→enabled transition for live-restore itself — no restart needed, zero container impact.** This generalizes [[docker-daemon-restart-risk]] beyond "many options are reloadable" to a verified-against-source confirmation for these two specifically. Reusable fact for any future daemon.json change on production hosts: always check the live-restore/reload docs before assuming a restart is needed.

Full analysis + exact command block (backup, edit, validate JSON, reload, verify via `docker info` + before/after `docker ps` diff) posted at https://github.com/lucas42/lucos/issues/307#issuecomment-5860583841. Target config matches the pre-rebuild rescued daemon.json exactly (verified by extracting `avalon-host-config.rescue-2026-09-14.tar.gz` on xwing) — plain `https://docker.l42.eu` mirror URL, not the untested `localhost:8038` alternative #106 speculated about (mirror confirmed healthy/reachable from avalon itself).

Needs root — lucas-agent has no passwordless sudo on avalon, so lucas42 applies it. Follow-up once done: lucas42/lucos#300 (merged host-setup runbook) should carry both settings so the next rebuild doesn't drop them again — comment added there too.

**RESOLVED 2026-09-28**: lucas42 applied it (16:29:43Z 2026-09-27), verified and closed by me. Verification technique worth reusing: "container still Up" alone doesn't prove a reload-not-restart — check `systemctl show docker --property=ActiveEnterTimestamp,NRestarts` for daemon-process continuity (unchanged since rebuild boot, `NRestarts=0`, proves dockerd itself never restarted) plus per-container `StartedAt` timestamps for ones that predate the reload. For "pulls go through the mirror," a live test pull of an image confirmed absent beforehand (`hello-world`), cross-checked against `lucos_router`'s access log (`?ns=docker.io` query param + `docker/<version>` user-agent on the request) is definitive — the mirror registry/web containers' own logs didn't show the request, only the router's did, so check the router first for this kind of proof next time. Full verification comment: https://github.com/lucas42/lucos/issues/307#issuecomment-5874304521
