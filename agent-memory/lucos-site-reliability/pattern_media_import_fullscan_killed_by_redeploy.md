---
name: pattern-media-import-fullscan-killed-by-redeploy
description: lucos_media_import all_files check red = weekly full scan hard-killed mid-run by routine redeploys; SIGTERM handler can't fire (cron grandchild). Tracked lucos_media_import#173.
metadata:
  type: project
---

`lucos_media_import` `all_files` monitoring check red (schedule-tracker staleness, debug "Job last ran at <date>, which is N seconds ago, threshold 1211400s") = the **weekly full-library scan never completing**, NOT the per-minute new_files scan (which is healthy and separate).

**Mechanism (lucos_media_import#173, found 2026-06-23):**
- `import.py` = full scan, cron `45 00 * * Thu`, long job (~12h: last clean run 06-04 ran 00:45→12:50). `new_files.py` = every minute (fine).
- It's **resumable**: checkpoints per top-level dir to `/var/state/import_checkpoint.json` (persistent vol `lucos_media_import_state`); only clean completion runs `clear_checkpoint()` + posts schedule-tracker success.
- Container **PID 1 = `startup.sh`** (shell→`cat`); `cron` is a child; `import.py` is a **cron GRANDCHILD**. `docker stop` SIGTERMs PID 1 only; shell doesn't forward → after grace, `import.py` is **SIGKILLed**. Its SIGTERM handler (meant to flush checkpoint + post failure) **never runs** → job dies silently, zero schedule-tracker update (success OR failure).
- Frequent morning Dependabot redeploys (~07:xx) land mid-scan on Thursdays → scan killed before finishing the big dirs (bandcamp/classical/iTunes…). Tell: stale checkpoint mtime PRECEDES that day's deploy (e.g. ckpt 06-18 07:05, deploy 06-18 07:28) + no schedule update.

**Diagnosis recipe:** `docker exec lucos_media_import` → `ls -la /var/state/import_checkpoint.json` (exists = last run never finished), `cat` it (completed_dirs vs `ls "/medlib/ceol srl"` total), `ps -eo pid,ppid,comm` (confirm PID1=startup.sh, import.py under cron), correlate ckpt mtime with loganne `systemDeployed=lucos_media_import` times.

**One-off restore = ad-hoc resume run** (skips completed dirs, finishes the rest, clears ckpt, posts success → check green):
`docker exec -d lucos_media_import sh -c 'cd /usr/src/app && nohup pipenv --quiet run python -u import.py > /tmp/adhoc_import.log 2>&1'`
Verify via end-to-end run, NOT `/_info` (cron path doesn't touch it). Confirmed 2026-06-23: resume ran clean, 0 errors, ~440MB free — leans AGAINST OOM.

**Secondary (sysadmin) angle:** xwing is RAM-constrained (906 MiB total). OOM SIGKILL would look identical (handler bypassed). Confirm/rule out via `dmesg|grep -i oom`/`journalctl -k` (needs root → sysadmin). [[pattern_backups_empty_repo_fails_run]]

**ORDERING BIAS (2026-08-07, #173):** `import.py` walks `sorted(os.listdir(dirpath))`; Python sorts **uppercase before lowercase**, so the 12 lowercase dirs (`artists`, `bandcamp`, `classical`, `comedy`, `compliations`, `compositions`, `iTunes`, `mixes`, `newgrounds`, `qobuz`, `songbird`, `symphony of science`) are **scanned LAST every run** — least margin, always the first dropped when a run is killed. ⚠️ This is a bias, **NOT** "never scanned": runs DO complete (last success 2026-07-30 13:01:09Z, errors=0, i.e. all 27 dirs). I published "never reached / 72% unreachable" on 2026-08-07 and retracted it — see the ⛔ note in [[pattern_new_files_unguarded_loop_poison_file]] on why `completed_dirs` is not a history.

**SIZING (measured 2026-08-07):** library ≈ **13,138** mp3s. Rate ≈ **3.36 s/track** (07-30 run: 00:45→13:01 = 12.27h ÷ 13,138) — corroborated by 3.72 s/track median from an ad-hoc re-import. Cost is paid **per file per run** even for already-indexed files (fingerprint precedes the API's `noChange`), and `maxlength=60` caps decode so per-track cost is ~constant. `artists` = **6,510** tracks ≈ **6.1h alone**, and is the FIRST lowercase dir — so it can't finish in a post-04:05 window and never checkpoints. Largest first-level subdir: `artists/Slade` 589 (~33min) → **per-subdirectory checkpointing suffices; a files-processed cursor is over-engineering**. Edge case: loose files at a top-level root (`bandcamp` 278, `songbird` 184) need their own checkpoint unit.

**Durable fixes in #173:** (1) make import.py reachable by SIGTERM (run as PID1 / tini / exec / trap-forward in startup.sh) — ends silent death; (2) finer-than-per-top-dir checkpointing (a single oversized dir like iTunes can stall forever); (3) deschedule the scan off the deploy window. xwing SSH = `xwing-v4.s.l42.eu` (accept-new host key first time).
