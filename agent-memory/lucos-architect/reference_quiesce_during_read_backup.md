---
name: quiesce-during-read-backup
description: Engine-agnostic consistent-backup pattern (docker pause) and its failure modes — lucos_backups ADR-0002 strategy model
metadata:
  type: reference
---

**The defect behind torn DB backups: the *smear*.** `tar`/`rsync` reads a volume over seconds-to-minutes while writes continue → the copy spans many instants, not one. Not engine-specific; afflicts any live-read backup. (lucos_backups `volume.py archiveLocally`, live-tar of crown-jewel SQLite stores aithne `credential_store` + `creds_store`.)

**lucas42's constraint (2026-06-17, #345):** NO database-specific backup strategies. Rejected the per-engine `sqlite`/`postgres`/`redis` verb proliferation (#344/#345). One general mechanism only.

**The two general cures for a non-atomic copy:** (a) CoW filesystem snapshot (atomic instant) — RULED OUT, hosts are ext4, no LVM/ZFS/btrfs (per SRE; revisit if FS ever changes — CoW would be superior, ms freeze); (b) **quiesce-during-read** = `docker pause` the owning container around the *local* read, then unpause. Relies only on two universal properties: a frozen-writer read is a true point-in-time image (cleaner than a power-loss crash — captures page cache), and every crash-safe engine recovers a crash-consistent image via its own WAL/journal replay. Genuinely engine-agnostic; for WAL engines *more* correct than `.backup`.

**Guarantee = crash-consistency, NOT application-consistency.** Sufficient for single-DB-per-volume (recovery → last committed txn). Does NOT give cross-volume consistency, but lucos backs up per-volume anyway (pre-existing, not a regression). State precisely; don't over-claim.

**I ratified this (#344, 2026-06-17) with conditions — these are the reusable failure modes:**
1. **Guaranteed unpause is the dominant new risk.** Pause held across a hung/failed/crashed copy = real outage. Unpause on EVERY exit path + time-bound the pause (exceed → unpause + fail loud) + independent watchdog.
2. **Pause only the fast LOCAL read, never the WAN transfer.** `full-snapshot` already splits local-tar (`archiveLocally`) from WAN-scp (`backupToAll`) — pause is cheap. But `backupIncremental()` rsyncs DIRECTLY from the live volume across the WAN (no local staging) — quiescing it as-built freezes for the whole transfer. Needs local-staging restructure or exemption.
3. **Quiesce by presence-of-live-in-place-writer, not blanket** (keeps it engine-agnostic, not per-engine). Exempt append-only immutable stores (photos) where a multi-min freeze "fixes" negligible smear — wrong trade. [[feedback_check_value_when_fix_complexity_grows]]
4. Monitoring blast radius: paused container fails healthcheck → keep freeze short or suppress (planned-maintenance).
5. Owning-container discovery + edge cases: not-running (copy direct, no pause) / multi-writer (pause all) / never self-pause.
6. Carry forward: fail LOUD (no silent live-tar fallback) + acceptance gate = real ad-hoc backup + restore `PRAGMA integrity_check`, NOT green `/_info`.

Status: ratified the approach; SRE writes replacement design → lucas42 final sign-off. Both SRE reframe write-ups (#344/#345) failed to post (literal `@/tmp/...`). See also [[reference_encryption_at_rest_vs_ransomware]].
