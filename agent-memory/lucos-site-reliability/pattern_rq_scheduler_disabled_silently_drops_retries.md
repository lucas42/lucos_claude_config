---
name: pattern-rq-scheduler-disabled-silently-drops-retries
description: RQ worker.work(with_scheduler=False) + Retry(interval=[...]) silently abandons every once-failed job forever; job status reads "scheduled" and no alert fires
metadata:
  type: project
---

An RQ worker started with `worker.work(with_scheduler=False)` while jobs are enqueued with `Retry(max=N, interval=[...])` **permanently loses every job that fails once**. A retry with a non-zero interval parks the job in the `ScheduledJobRegistry` (`rq:scheduled:<queue>`); only the worker's built-in scheduler moves it back. Scheduler off → nothing ever does.

**Why this is nasty:** the abandoned job's `status` field reads `scheduled`, not `failed`. There is no failed registry entry, no log line, no alert. Monitoring stays green while work is dropped.

**How to detect (any repo using RQ):**
```
redis-cli ZCARD rq:scheduled:<queue>          # backlog size
redis-cli ZRANGE rq:scheduled:<queue> 0 -1 WITHSCORES   # scores are unix due-times
```
Due-times far in the past = stranded. Then `grep -rn with_scheduler` in the worker source.

**Confirmed instance:** lucos_photos, 2026-07-19. 35 stranded jobs, oldest due 12 Mar 2026 (~4 months). Present since the initial RQ commit 66e611e (4 Mar 2026). Raised as lucas42/lucos_photos#475 (P2 suggested).

**The masking effect worth remembering:** in lucos_photos, 29 of the 35 stranded jobs were `process_photo`/`process_video` and were invisible because a separate 60s sweep thread re-enqueues anything stuck in `pending`/`processing`. Only `generate_profile_picture` — which had no sweep — showed user-visible damage. **A safety-net sweep on one job type can hide a queue-wide defect for months.** When one job type degrades silently, check whether sibling job types are being rescued by a backstop rather than actually succeeding.

**Unverified hypothesis for the original hang** (flagged as such in the issue, not proven): RQ forks a work horse per job from a parent that also runs a background sweep thread. Forking from a threaded parent can deadlock the child on an inherited lock (logging / SQLAlchemy pool). Evidence consistent — child logged nothing at all and died at its 180s timeout, while jobs forked moments later succeeded — but not reproduced.

Related: [[feedback_treat_empty_tool_output_as_unknown]], [[pattern_python_stdout_buffered_swallows_diagnostics]] (both are "absence of a log line is not absence of a problem").
