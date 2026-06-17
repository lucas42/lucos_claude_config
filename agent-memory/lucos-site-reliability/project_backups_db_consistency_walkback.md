---
name: backups-db-consistency-walkback
description: lucos_backups torn-snapshot fix walked back from per-engine strategies to engine-agnostic quiesce; host FS rules out CoW snapshots
metadata:
  type: project
---

lucos_backups `full-snapshot` `archiveLocally()` `tar`s the **live** volume for up to 600s = a temporally-inconsistent *smear* (worse than a crash). Same bug in the `incremental` rsync path (`backupIncremental()`). For live DBs → torn snapshot, only discovered at restore.

**Walk-back (lucas42, 2026-06-18):** rejected the database-specific fix (#344 `backup_strategy:"sqlite"` via `.backup`, #345 `postgres`/`pg_dump`). #346 (sqlite capability PR, was code-reviewer-approved, no auto-merge) → **converted to draft**, likely discarded. #344/#345 → Needs Analysis, owned by SRE.

**Sanctioned direction = engine-agnostic point-in-time consistency, NOT per-engine.** Problem is atomicity not engine-knowledge: any crash-consistent image is recoverable by every engine's own journal/WAL/AOF. Reframe = separate **consistency** (quiesce) from **transport** (full-snapshot vs incremental, ADR-0002).

**Why CoW snapshot is OUT (durable host fact, verified 2026-06-18):** docker volumes on all 3 hosts are plain **ext4 single partition** — avalon/xwing `/dev/sda2`, salvare `/dev/mmcblk0p2`; **no LVM, no ZFS, no btrfs** (avalon has the btrfs *binary* but root is ext4). LVM/ZFS snapshots would need a host-storage re-architecture — not worth it.

**Chosen agnostic mechanism = quiesce-during-read:** `docker pause` the owning container around the read, then unpause. Verified on avalon: `docker ps --filter volume=<name>` resolves owner (credential_store→lucos_aithne, contacts_db_data→lucos_contacts_db); `docker pause` available. **All 9 DB volumes live on avalon and are small** — media_metadata_api_db 239MB (largest), contacts 125MB, photos_postgres 74MB, eolas 62MB, repos 4.7MB, rest kB → freeze window single-digit seconds nightly = negligible. Bound it for future-large volumes via pause→local `cp -a` to staging→unpause→tar staging.

**Status 2026-06-18:** architect RATIFIED quiesce (6 conditions) + SRE posted replacement design on #344 → **awaiting lucas42 final sign-off**, then implementation (volume.py + volumes.yaml `quiesce` flag + ADR-0002 update). Design key points: per-volume `quiesce:true` keyed on "live in-place writer" NOT engine; pause wraps only a fast UNCOMPRESSED local capture→unpause→gzip+scp from staging (freeze ~1-3s); guaranteed unpause = single host-side script `trap…EXIT` + independent `sleep` watchdog (SIGKILL/SSH-death) + time-bound fail-loud; **`incremental` path EXEMPT** (rsyncs live across WAN, no staging — only user is append-only photos; guard errors if `quiesce:true` set on incremental vol); photos exempt; loud-fail + real-restore `integrity_check` gate. 8 DB vols to flag.

**Process lesson (cost me a repost):** `gh-as-agent -f body=@/tmp/file` posts the LITERAL `@path` string (raw-field, no file read) — silent fail, returns html_url+success. Use heredoc/command-sub `-f body="$(cat file)"` and ALWAYS re-fetch to verify the body rendered. Doc already warned (agent-github-identity.md:53); added a verify-after-post backstop there. See [[pattern_backups_invalid_effort_crashes_host_tracking]] for related backups config mechanics.
