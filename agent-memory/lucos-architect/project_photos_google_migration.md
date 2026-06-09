---
name: photos-google-migration
description: lucas42/lucos_photos#424 — migrate ~78GB historical photos from Google Photos; PLAN FINALISED 2026-06-09, 4 tickets spawned (#425/#427/#426 + lucos_backups#318)
metadata:
  type: project
---

# Google Photos → lucos_photos migration (lucas42/lucos_photos#424)

**PLAN FINALISED 2026-06-09** — lucas42 answered all 5 Qs (his comment on #424, 2026-06-08); 4 tickets spawned, coordinator to board. Decisions:
- **Dedup = clean date-cutoff by date TAKEN, cutoff 1 Feb 2026** (Option C — temporally-disjoint sets, no content dedup built). Import only Google photos taken <1 Feb 2026; **delete all lucos_photos photos taken <1 Feb 2026 first** (Google becomes authoritative pre-cutoff, phone post-cutoff). Accepted: clean cutoff won't backfill phone-upload-misses in overlap window.
- **Description field**: add as prep, display in `.photo-metadata` (display-only, no UI editing).
- **Faces**: unnamed OK; explore reusing Google face *grouping* to avoid per-person fragmentation (spike).
- **Run on avalon**; aurora free space **954.4G** (now verified, was the blocker).
- **Backups**: incremental/content-addressed confirmed, own ADR in lucos_backups.

**Spawned tickets:**
- lucas42/lucos_photos#425 — description field (prep) — Ready
- lucas42/lucos_backups#318 — incremental/content-addressed backups for photos volume + ADR (docs/adr/0002) — Ready, **blocker**
- lucas42/lucos_photos#427 — resumable migration script + cutover (date-cutoff + pre-cutoff deletion phase + runbook) — **Blocked** by #425 + lucos_backups#318
- lucas42/lucos_photos#426 — spike: reuse Google face grouping — Ready, low-pri, non-blocking
- Cutover run order: off-cron seed + **verified RESTORE** → delete pre-cutoff → import via POST /photos. **#427 owns the off-cron seed-staging + verified-restore-before-import gate** (deferred from lucos_backups ADR-0002 per lucas42 on backups#318, 2026-06-09 — ADR records only that rsync `--link-dest` *supports* `--seed`; the seed planning/execution + restore-test live in #424/#427, not the ADR). Gate upgraded from "verified backup exists" to "verified restore" (a backup never restored is a hope). SRE owns the other 2 ADR parts (collapse-to-unconditional now aurora rsync verified; host-level-rsync soft-avoid).

---
## Original framing (posted 2026-06-08, comment on #424) — retained for design context

**Import endpoint sufficiency:** `POST /photos` (api/app/routers/photos.py) streams→SHA-256→dedups on hash; accepts `X-Taken-At` header (epoch ms); worker overwrites taken_at with EXIF if present. Two gaps: (1) **no `description` column** in MediaItem (sha256_hash/taken_at/uploaded_at only) — migrating Google descriptions needs schema migration + endpoint/worker + UI = prep work; (2) dates covered via Takeout JSON sidecar `photoTakenTime` → X-Taken-At.

**Face tags:** Google export won't give person *labels*; lucos_photos re-detects faces (InsightFace) but unnamed. Worth a hedged look at Takeout JSON `people` array (historically inconsistent).

**Dedup crux (the hard problem):** current dedup = exact SHA-256. Google reprocesses (re-encode/metadata-rewrite) so a Google copy of a photo already in lucos_photos (phone dual-upload overlap) has a DIFFERENT hash → exact-byte dedup misses it. Options: (A) perceptual/pHash = permanent feature + false-positive risk; (B) date+heuristic; **(C) date-cutoff exclusion = my recommendation** — overlap is purely temporal, so migrate only Google photos OLDER than the dual-upload start date; reconcile overlap later only if gaps. Boring/robust. Q to lucas42: clean cutoff (+cutover date) vs pay for perceptual up front.

**Resumable script:** client driving POST /photos; local ledger (sqlite/append-file) of confirmed files, append only after 201/200, skip on resume (avoids re-pushing 78GB). Endpoint idempotent on hash = safety baseline. Run on/near photos host with Takeout mounted; **route through POST /photos NOT direct uploads-mount write** so `MIN_FREE_DISK_SPACE` guard stays active. Throttle concurrency.

**Backup = forcing function (SRE + sysadmin input, durable infra facts):**
- Current backup = lucos_backups daily FULL `tar -czf` of photos volume → copied to backup hosts. **Already broke 2026-06-08 at 6.6GB** (lucos_backups#309, closed): daily aurora copy timed out vs old 600s cap; fix raised 600s→7200s (band-aid for 6.6GB).
- **Binding constraint = cross-host COPY WINDOW, not storage** (SRE). Single scp over home WAN leg avalon→xwing(ProxyJump)→aurora; throughput <~11 MB/s. Post-migration ~85GB ≈ 2h+ → re-breaks the fresh 2h cap day one. gzip≈0 on JPEG/video; re-shipping ~99%-identical append-only bytes daily is pathological → recommend **incremental/content-addressed** (rsync --link-dest min; restic/borg better).
- photos volume `skip_backup_on_hosts: [salvare, xwing]` → **aurora (QNAP) is the SOLE backup destination** + local avalon copy. Aurora free disk **unverified** (SSH flaky via xwing) = the one timeline blocker; need ~550GB+ for first week. Steady-state ~22 retained instances ≈ ~11TB at 500GB volume.
- Failure modes: truncated dest tarball (no resume/atomic rename) = silent-restore-corruption risk (backupToAll DOES raise on timeout, so run marked failed — good); first-full copy collides with daily cron → stage off critical path.
- avalon source host: 1.3TB free → uploads landing zone fine. Worker mem_limit 3g/no CPU cap; InsightFace pins a core hours-to-days over 78k photos — survivable, monitor.

**Deferred:** backup-mechanism change for photos volume is prep that GATES the migration → will need its own lucos_backups ticket (SRE/sysadmin-owned), **NOT raised yet** — pending lucas42's Q5 answer (incremental vs provision aurora).
