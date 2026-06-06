---
name: pattern-loganne-client-level-required-arg
description: loganne python client added a REQUIRED `level` positional arg; callers missing it crash with TypeError
metadata:
  type: project
---

The loganne python client's `updateLoganne` signature is now `(type, humanReadable, level, url=None, **extra_data)` — **`level` is a required positional arg**. Any caller still on the old `updateLoganne(type=…, humanReadable=…, url=…)` form crashes with `TypeError: updateLoganne() missing 1 required positional argument: 'level'`.

**Diagnostic signature:** a scheduled-job check red with schedule-tracker debug `"… failed: updateLoganne() missing 1 required positional argument: 'level'"`. The crash lands wherever the call is — if it's the final reporting `updateLoganne` (common pattern: emit event then `updateScheduleTracker(success=True)`), the job does its real work but never posts the success tick, so the check reports failure while functionality looks fine (esp. if a separate webhook path keeps data current).

First hit 2026-06-06: `lucos_arachne` `ingest.py:164` `updateLoganne(type="knowledgeIngest", humanReadable=…, url=BASE_URL)` — every scheduled `run_ingest()` crashes at the end; webhook-driven per-track ingestion (separate path) unaffected, so the graph stays current. Tracked: **lucos_arachne#608**.

**Estate risk:** a shared client gaining a required positional arg is a breaking change for every un-updated caller. Flagged to team-lead 2026-06-06 for a possible estate-wide sweep of `updateLoganne(` call sites. Related: [[feedback_loganne_scope]], [[feedback_enumerate_existing_mechanisms]].
