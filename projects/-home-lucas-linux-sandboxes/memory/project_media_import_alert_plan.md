---
name: lucos_media_import alert clearance plan
description: Plan to clear the schedule-tracker lucos_media_import alert — implement #142 first, then trigger a manual re-run
type: project
originSessionId: 8f305362-71cd-487d-8b24-b557083ef013
---
Next session priority: clear the `schedule-tracker.l42.eu` lucos_media_import alert (currently fail_count=296, tracked in lucos_media_import#143).

**Plan:**
1. Dispatch lucos_media_import#142 (deploys killing long-running import runs) — already moved to top of the Ready column
2. Once #142 is merged and deployed, trigger a manual re-run of the import job
3. The re-run should complete without being interrupted by a deploy, bringing the error count to 0 and clearing the alert

**Why:** The fingerprint fix script has already patched 94 tracks; track 15188 (the last duplicate) was manually deleted by lucas42 on 2026-04-27. Thursday's scheduled cron would also clear it, but we'd rather not wait until then.

**How to apply:** At the start of the next session, dispatch lucos_media_import#142 before running routine ops checks.
