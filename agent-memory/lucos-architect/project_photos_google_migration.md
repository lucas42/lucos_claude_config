---
name: photos-google-migration
description: lucas42/lucos_photos#424 — plan migration of ~78GB historical photos from Google Photos; framing posted 2026-06-08; dedup crux + backup-mechanism forcing function
metadata:
  type: project
---

# Google Photos → lucos_photos migration (lucas42/lucos_photos#424)

Framing posted 2026-06-08 (comment on #424). ~78GB historical photos from Google Photos. Prep-planning ticket; not yet building. 5 product/one-way-door Qs back to lucas42.

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
