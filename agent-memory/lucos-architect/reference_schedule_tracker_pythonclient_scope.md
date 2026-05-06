---
name: lucos_schedule_tracker_pythonclient scope
description: pythonclient is for talking to schedule_tracker's API only — not a generic third-party API wrapper
type: reference
---

`lucos_schedule_tracker_pythonclient` is **only** a client library for the schedule-tracker API itself (i.e. helps cron scripts POST their `success`/`error` status to schedule-tracker). It does **not** wrap third-party API calls.

Retry-with-backoff logic for transient failures from external APIs (e.g. Google People API 502/503/504, Facebook API errors) belongs in the cron script itself, in the consuming repo (e.g. `lucos_contacts/googlesync_import`), not in the pythonclient.

**Why:** the pythonclient's job is the schedule-tracker contract; transient-upstream handling is consumer-specific (depends on the third-party API's failure modes, what's worth retrying, what's idempotent). Mixing the two would couple every consumer's retry policy to the schedule-tracker client.

**How to apply:** when recommending caller-side retries for flaky third-party APIs in cron jobs, locate the work in the consuming repo's cron script, not in `lucos_schedule_tracker_pythonclient`. If the same retry shape appears in multiple consumers, consider a different shared library (or an HTTP-client wrapper), not the schedule-tracker client.

Source: lucas42 correction on lucas42/lucos_schedule_tracker#70 (2026-05-06). My initial recommendation suggested putting retry logic in pythonclient — wrong scope.
