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

**Durable fixes in #173:** (1) make import.py reachable by SIGTERM (run as PID1 / tini / exec / trap-forward in startup.sh) — ends silent death; (2) finer-than-per-top-dir checkpointing (a single oversized dir like iTunes can stall forever); (3) deschedule the scan off the deploy window. xwing SSH = `xwing-v4.s.l42.eu` (accept-new host key first time).
