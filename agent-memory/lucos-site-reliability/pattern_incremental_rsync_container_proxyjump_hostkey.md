---
name: incremental-rsync-container-proxyjump-hostkey
description: lucos_backups incremental (rsync --link-dest) path fails host-key verification on the ProxyJump hop because the ephemeral rsync container has empty known_hosts; photos backup broken pending lucos_backups#327
metadata:
  type: project
---

The lucos_backups `incremental` backup_strategy (ADR-0002, #324) runs rsync inside a fresh `docker run` container **as root with an empty known_hosts** (`/root/.ssh` doesn't even exist in `lucas42/lucos_backups` image). `host.py::_container_ssh_command` sets `ssh -o StrictHostKeyChecking=no -o ProxyJump=lucos-backups@xwing…`, but that flag covers only the **outer** hop (→aurora) — it does **NOT** cover the **ProxyJump hop to xwing**, which then fails host-key verification.

**Diagnostic signature:** rsync exit 255 + `Host key verification failed` + `Connection closed by UNKNOWN port 65535` + `connection unexpectedly closed (0 bytes received)`. Note: with `StrictHostKeyChecking=no` set, an unknown *target* key is auto-accepted — so a host-key failure WHILE that flag is set means a hop the flag isn't reaching (the jump). The old full-snapshot host-side scp path works because it runs as the lucos-backups OS user whose known_hosts trusts xwing+aurora; the container has neither.

**Status (2026-06-12):** `lucos_photos_photos` is flipped to `incremental` (configy#230 live) and v1.1.13 is deployed, so the path is LIVE and BROKEN. The nightly create-backups cron (03:25/15:25 UTC) routes photos through it and fails identically → `create-backups`/`host-tracking-failures` red for `lucos_photos_photos`, one re-alert per run. **This is NOT a new outage** — the old full-snapshot path was already failing on this volume (600s scp timeout, [[pattern_backups_invalid_effort_crashes_host_tracking]] sibling #309). Discovered running the off-cron seed (`scripts/seed-volume.py lucos_photos_photos`) — the seed gate worked as designed, catching it before lucos_photos#427's big import.

**Why:** verified by running the seed end-to-end on v1.1.13; confirmed empty container known_hosts directly. Candidate fixes in the issue (ProxyCommand-with-flag, or mount real known_hosts — latter preferred, keeps verification).
**How to apply:** if create-backups is red for `lucos_photos_photos` during ops checks, it's lucos_backups#327 — don't re-investigate or treat as fresh incident. Once #327 lands + redeploys, re-run the seed and verify a real atomic `<date>/` dir (not `.partial`). Tracked: lucos_backups#327 (blocks lucos_photos#427).
