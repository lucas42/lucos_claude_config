---
name: pattern-verifying-a-create-backups-run
description: How to trigger and actually verify an ad-hoc lucos_backups create-backups run — no HTTP trigger exists, output goes to a FIFO that loses tracebacks, the monitoring check has a 72h blind spot, and a green board can sit on top of a failed run
metadata:
  type: pattern
---

# Triggering and verifying `create-backups` (learned the hard way, 2026-09-16)

## Trigger

**There is no HTTP endpoint.** `server.py` only exposes `/refresh-tracking` and `/refresh-config` as POSTs. The run is a cron entry (`src/backups.cron`, 03:25 and 15:25), so an ad-hoc run means invoking the same command. The image has **no bash** — use `.` not `source`:

```sh
docker exec -d lucos_backups sh -c "cd /usr/src/app && . scripts/init-agent.sh && \
  pipenv run python -m scripts.create-backups > /tmp/adhoc-backup.log 2>&1"
```

**Redirect to a file, NOT to `/var/log/cron.log`.** That path is a **FIFO** drained to the container's stdout by `startup.sh`, where it interleaves with the HTTP access log (a `/_info` healthcheck every 10s). A traceback written there loses its body: on 2026-09-16 the first run's exception line survived and every frame after it was gone, so the failure was unexplainable. Second run to a real file: 417 clean lines.

## Duration

**~15 minutes, not ~45.** Both 2026-09-16 runs took 15–16 min end to end. The ~2730s figure from 2026-06-08 is stale and I misused it that night to reason that a 16-minute run must have died early — it hadn't; that's just the normal duration now. Don't infer failure from a short run.

## Verifying — three signals, in order of trustworthiness

1. **loganne event** — a clean run posts `"124 archives successfully backed up"` (source `lucos_backups`, type `backups`). **No event = it did not complete cleanly.** This is the one I'd trust first.
2. **schedule-tracker** `lucos_backups/create-backups`: `errors=0`. An errored run leaves `errors=1` — and see the blind spot below.
3. **The captured log** ends with `Backups Complete` and contains no `Traceback`/`Error` lines. The only expected "Skipping" lines are configured `skip_backup_on_hosts` exclusions for `lucos_photos_photos`.

## ⚠️ The blind spot — a green board over a failed run

The monitoring check is *"any of the 2 most recently finished runs succeeded, and the most recent was within **259200s = 72 hours**"*. The job runs daily. So:

- **One missed or failed run is invisible for three days.** On 2026-09-16 `lucos_backups` showed **all sixteen checks green** while the last successful run was 2026-09-13 — 70.7h, i.e. ~75 minutes of headroom left.
- Worse, when the triggered run *failed*, lucas42/lucos_schedule_tracker#96's false-recovery behaviour nulled `last_success`, so `age` then measured the **failed** run and the job looked freshly completed. The single field that would have exposed it was overwritten by the failure.

**So: never read the backups dashboard as evidence that backups work.** Trigger a run and read loganne. This is the concrete instance behind [[reference_schedule_tracker_detection_semantics]] and was posted to lucas42/lucos_schedule_tracker#96.

## Progress-watching gotchas

- `docker top lucos_backups | grep create-backups` **matches the lingering `sh -c` wrapper**, whose command line contains the same string, so it reports "still running" long after the Python process exits — it did so for 51 minutes. Grep for `python -m scripts.create-backups` *and* confirm against schedule-tracker, or you will misreport the duration.
- Destination-side progress: `find /srv/backups -type f -printf '%T@ ...' | sort -n` on xwing/salvare. **Sort numerically on `%T@`**, not lexically on `%TH:%TM` — and note xwing/salvare print local (BST), an hour ahead of the UTC you are reasoning in.
- `docker exec` into this container gets slow while a run is active; `docker top` stays cheap.
