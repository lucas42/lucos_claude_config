---
name: project-photos-migration-prep
description: "Google Photos → lucos_photos migration (#427/#577): full import RUNNING unattended since 2026-10-12 12:30 UTC, ETA ~2026-10-26; what the next session must do"
metadata:
  node_type: memory
  type: project
  originSessionId: 612d7504-31f9-4642-9197-51f1fe70c266
  modified: 2026-10-13T22:27:51.100Z
---

**UPDATE 2026-10-29:** agent part of step 9 DONE (import.env deleted, /srv/photos-migration emptied, 186GB freed). AVIs transcoded+imported; originals in one-off store as `Videos 2011-12.tar.gz` (verified on xwing+salvare). 9 missing ids = lucas42 manually deleted TikTok videos. #577 Owner → lucas42 for: revoke import key, redeploy photos + confirm key gone from CLIENT_KEYS, sudo rm -rf /srv/photos-migration. Then #577 closes; #619 → developer; #621/#623 dispatchable.

**UPDATE 2026-10-28:** the import finished uploading on 2026-10-26 at 02:31Z: 96,708 uploaded, 1 FAILED, exit 1. The failure is the expected over-limit #597 video (see SRE comment on #577, 10-18). #577 Owner was moved to lucos-developer, still Ready/High. Next: one step-6 resume (should exit 0), post-import checks, prename (no lucas42 gate: the 107 pre-cutoff deletion was approved and done on 2026-10-12), #599 videos decision before step 9 clean-up. Dispatched to the developer on 2026-10-28; resume running.

**State at 2026-10-12 ~16:00 UTC:** full import running on avalon in detached container `lucos_photos_migration_import` (`--concurrency 1 --max-pending 10 --max-per-hour 300`, IO caps 5mb/50), started 12:30:56 UTC. media_item 4003; ~95,700 of 97,449 remain → import ETA about **2026-10-26 ~23:00 UTC** if it never stops. Team shut down at lucas42's request, so **no stop-rule watch runs between sessions** — the container keeps going on its own; if it exits, it stays stopped until a session notices.

**Why:** lucas42 accepted ~13½ days at 300/h (SRE) after the unpaced run stalled avalon at 10:48 (worker duty cycle + swap on its single disk).

**How to apply — next session:**
- Runbook "Long runs" daily check: container `Up`, recent log line, loganne `backups` event (backups run **15:25 UTC**; 03:25 is a retry no-op by design). If exited: check the exit code per the runbook table, `docker rm`, rerun step 6 (ledger skips done files). Refresh `/srv/photos-migration/app/google_takeout_import.py` from origin/main + hash check first if the script changed.
- Stop rule (#589): loganne `monitoringAlert` for a non-photos service (match hostname; there is NO "Sending alert" log line), or 3+ non-photos services failing fetch-info within 2 min, or pressure clause excluding lucos_photos_*, lucos_loganne and lucos_backups-spawned containers (rsync image + alpine `tar -C /raw-data`). Single :05–:12 blips = hourly rdf-exporter noise.
- Queued runbook fixes (do in a window, each merge redeploys photos): drop "Sending alert" → loganne monitoringAlert by hostname; exclude backup-spawned containers; script-copy refresh step (partly in #589).
- After import: count `failed` photo rows ("image file is truncated" = damaged Takeout originals, 8 by 2026-10-13; RQ retries can't fix them) and tell lucas42 which originals were unreadable. Then step 7 prename, step 8 checks, step 9 (delete import.env, lucas42 revokes `lucos_photos_import/production => lucos_photos/production`), empty /srv/photos-migration; lucas42 sudo-removes root-owned dryrun-skipped.tsv/dryrun2-skipped.tsv, raw-takeout and the dir.
- **Loganne holds only ~13–17h during the import** (10k-event cap; reported by SRE 2026-10-13). For the `backups` check use schedule-tracker; for stop-rule `monitoringAlert` history older than ~13h use the daily backup archives (fallback documented in `sre-ops-checks.md`).
- #573 dedupe doesn't collapse at import pace (by design, queue near-empty); the event flood fix is lucos_photos#596 (Ready/High, 2026-10-13).
- Open with lucas42: two `lucos_photos_*_moved-aside-2026-09-16` volumes still undecided.
- Related: [[project-avalon-disk-failure]]
