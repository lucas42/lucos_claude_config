---
name: project-avalon-disk-failure-294
description: RESOLVED 2026-09-16, ALL data recovered by 22:34 — avalon single-disk failure; estate rebuilt. Report lucas42/lucos#297 MERGED, follow-up PR lucas42/lucos#305. Photos were NEVER lost (aurora had them); final 2,253 items consistent. Rescue dir + privacy rule.
metadata:
  type: project
---

**RESOLVED 2026-09-16 03:39 UTC.** avalon's single non-RAID disk failed 2026-09-14 (~07:55 onset, host unmanageable 19:21). Data was rescued in OVH rescue mode, the host rebuilt on Debian trixie at the same IP, and the estate restored and verified. **Services ~1 day 20 hours; ALL DATA RECOVERY finished 22:34 that evening (~2d 15h from onset)** — the extra day spent recovering photos that were never lost. Incident report: **lucas42/lucos#297 — MERGED** 2026-09-16 08:29Z, live at `docs/incidents/2026-09-14-avalon-disk-failure.md`. Anything material after this goes in a fresh follow-up PR, per `references/incident-reporting.md`. Source issue lucas42/lucos#294; rebuild runbook lucas42/lucos#296.

## Still out / still open

- ~~Photo originals are NOT recovered~~ **RECOVERED 2026-09-16.** ⚠️ **I had the premise wrong: `lucos_photos_photos` was NEVER excluded from backups.** configy gives it `backup_strategy: incremental` + `skip_backup_on_hosts: [salvare, xwing]` — it lives on avalon, so it WAS backed up there. aurora's 2026-09-14 snapshot holds **2,250 originals / 5,941 files / 11GB**. What failed was the *recovery path*, not the backup: the server returned 200 from a DB hash lookup without checking the file existed, so the first full resync restored nothing (619 uploads, all 200, 4 files). Fixed by lucas42/lucos_photos#526 (both it and #525 now closed). **Lesson: "not recovered" and "not backed up" are different claims — check volumes.yaml before asserting the second.** See [[establish-source-scope-before-never-happened]] for the generalised rule.

**Final sequence, evening of 2026-09-16** (all verified; follow-up report PR lucas42/lucos#305):
1. Photos volume restored from aurora's 2026-09-14 snapshot (rsync via the xwing gateway), done 16:58. The existing volume was **moved aside, not overwritten** — the only reason 3 unique originals survived.
2. That exposed a volume/DB mismatch: the DB had been *running* all day while the files were a fixed point. lucas42's diagnosis: **two volumes captured at the same moment are consistent by construction; repair work afterwards never reproduces that for free.**
3. DB restored from the 2026-09-13 nightly ~22:20. ⚠️ The 09-14 photos snapshot is **byte-identical to the 09-13 one** (same filenames AND inodes — `--link-dest` hardlinks), and the rescued PGDATA's newest activity was 2026-09-13 03:04:30Z, so all candidates were equivalent.
4. The 3 unique originals (2 taken 09-14 post-snapshot, 1 from July never uploaded) pushed back via `POST /photos` **from inside the API container** — auth is any key in `CLIENT_KEYS` (flat set, not phone-specific), read from the container's own env. EXIF `DateTimeOriginal` is authoritative, so dates were correct without a header; `taken_at` is never defaulted to now.
5. **Final: 2,253 items, 4 consistency counts all zero, curation intact (127 confirmed faces / 66 named).**

⚠️ **A resync re-transmits everything**: the SHA is computed from the request body as it streams, so the "already have it" check happens only *after* the whole file arrives. 11GB moves regardless. Measured: 2,253 files over 10.2h wall-clock but only ~32min of active transfer — the phone idles.

- ~~`lucos_mail_smtp` down~~ **FIXED 07:31 2026-09-16** (lucas42/lucos_mail#80). ⚠️ It was **NOT** an unchanged image: lucos_deploy_orb resolves the version from the newest git tag, not the checked-out commit (lucas42/lucos_deploy_orb#193, Critical), so a different image built during the rebuild was deployed, carrying unpinned dovecot with a stricter validator (`2.4` vs `2.4.0`). Pinning: lucas42/lucos_mail#81.
- **The DNS secondary on xwing holds no zone files on disk** and served all five zones from memory for two days. lucas42/lucos_dns#135 — root cause NOT found; the four obvious explanations are ruled out in the issue.
- **lucas42/lucos_monitoring#313** — a check whose source disappears reads green, not unknown. Architect writing an ADR.
- Others: lucas42/lucos#299 (CI bootstrap, documentation-only, **owner me**), lucas42/lucos#301 (aurora recovery path, me), lucas42/lucos#302 (post-rebuild confirmations, me), lucas42/lucos#300/#303/#304 (lucas42), lucas42/lucos_monitoring#312, lucas42/lucos_media_linuxplayer#146, lucas42/lucos_backups#415 (mine, and now also carries the 72h create-backups threshold evidence).

## The rescue directory — ⚠️ privacy rule

`~lucos-agent/emergency-backups-2026-09-14/` on **xwing and salvare**, mode 700. `README.md` there is the restore guide. **Nothing is deleted yet** — lucas42's rule: not until the rebuild has bedded in, and a while beyond (lucas42/lucos#304, revisit from 2026-09-30).

- **A credential-exposure disposition decided 2026-09-15 lives ONLY in that README's "Deliberately NOT copied" section. Never restate it in memory, commits, issues, PRs or #297** — lucos_claude_config and lucos are PUBLIC.
- **Mode 700 is not the real boundary**: `lucos-agent` already has root-equivalent access on xwing and salvare via `docker` group membership (lucas42/lucos_agent_coding_sandbox#102). Standing access, not new exposure — but don't describe the permission bits as the control.
- **The rescued SSH host keys were never installed.** The rebuild generated fresh ones (the runbook's documented fallback), so those private keys are now the only copies of a host that no longer exists.

## Facts worth keeping

- **Access topology (verified 2026-09-16):** agents reach **avalon, xwing and salvare each directly** — `~/.ssh/config` has no `ProxyJump`/`ProxyCommand`. **aurora is the only host behind a gateway** (xwing). I asserted otherwise in a risk assessment and it was load-bearing; see [[reference_aurora_access_and_rsync]] for aurora's working recipe.
- **Verification that mattered** (see [[pattern_verifying_a_create_backups_run]]): the first triggered `create-backups` run **failed** with every one of `lucos_backups`' sixteen checks green; the second succeeded — **124 archives**, matching every pre-incident run. Data checked against the README's figures: contacts 30 tables, eolas 41, photos 7 + `vector`, media 14,755 tracks / 121,274 tags `integrity_check ok`, worlds' activity log to 2026-09-14 00:16:29 (lucas42's last edit, in no backup).
- **DNS deadline is no longer live**: the secondary re-established contact with the rebuilt primary at 00:37 on 2026-09-16 and all five serials match.
- **Deferred:** ops Checks 3 and 4 from 2026-09-14 were never run.
