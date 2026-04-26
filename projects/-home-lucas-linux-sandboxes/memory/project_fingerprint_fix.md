---
name: lucos_media_import fingerprint fix in progress
description: fix_fingerprints.py running on xwing overnight; check lucos_media_import#143 in next ops checks
type: project
originSessionId: c582f973-fab7-4c4f-8276-2be77ffb33d1
---
`fix_fingerprints.py` was started detached on xwing at ~11:07 UTC 2026-04-26, inside the `lucos_media_import` container (pid 4003098). ETA ~23:00 UTC same day.

**Root cause:** pyacoustid 1.3.1 (Dependabot bump 2026-04-10) introduced its own fixed internal buffer, silently making the `io.DEFAULT_BUFFER_SIZE = 8192` workaround in `src/logic.py` a no-op. All tracks re-fingerprinted since 10 April got different fingerprints from their stored values (~95 affected).

**Fix:** Script walks all ~14,625 API tracks, re-fingerprints each, PATCHes any mismatched. Idempotent.

**What:** Check `lucos_media_import#143` in the next ops checks (2026-04-27):
1. Is the script done? `docker exec lucos_media_import ps aux | grep fix_fingerprints`
2. How many tracks were patched?
3. The monitoring alert (`lucos_schedule_tracker` / `lucos_media_import`) will only clear after Thursday's import cron (00:45 UTC 2026-04-30) runs successfully — the fix patches DB data but doesn't trigger the schedule-tracker.
4. After Thursday: verify alert cleared; if not, investigate new drift.

**Side finding:** Pi's json-file log driver drops ~58% of output under load — explains 27 errors in docker logs vs 95 reported to schedule-tracker. Worth a separate follow-up issue.
