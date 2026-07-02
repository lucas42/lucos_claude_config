---
name: reference-schedule-tracker-detection-semantics
description: How scheduled-job failures surface to monitoring (ADR-0004) and the check tolerance that (correctly) swallows intermittent failures — for "why didn't monitoring catch this cron failure?" questions
metadata:
  type: reference
---

**How a scheduled-job failure reaches monitoring (ADR-0004, lucas42/lucos#140):**
- Cron jobs POST `{system, job_name, frequency, status, message}` to `schedule-tracker.l42.eu/v2/report-status` (client pkg `lucos-schedule-tracker-pythonclient`, `job_name` REQUIRED, default frequency 86400s).
- schedule_tracker persists per-`(system, job_name)` state and **derives the check server-side**.
- Post-cutover, schedule_tracker's OWN `/_info` carries only the service's intrinsic health (I saw **0 job checks** there — don't conclude "nothing monitored"). The job checks are exposed at **`GET /jobs`** (queryable, no auth) and pulled into lucos_monitoring by **`fetcher_scheduled_jobs`**, attributed to the **owning `system`** row (e.g. `lucos_arachne`), NOT the `lucos_schedule_tracker` row.

**Check semantics (from a live `/jobs` entry, 2026-07-02):** `ok = (at least one of the 2 most-recently-finished runs succeeded) AND (most recent completion within the frequency-derived threshold; a 24h-frequency job showed 259200s = 3 days)`. Metrics: `age` (secs since last completion), `errors` (consecutive errors since last success). **⇒ red requires 2 CONSECUTIVE failed runs, or no completion within the staleness window.** A single/intermittent failure followed by a success stays GREEN by design — so "monitoring was green during transient failures" is CORRECT behaviour, not a gap. Don't call this a monitoring gap unless the failure was genuinely persistent (2+ consecutive). The pathological "fails exactly every other run forever" edge keeps data ~1 run stale without alerting — real but low-impact/self-healing; accept, don't build.

**arachne specifics:** bulk `ingest.py` reports **19 separate per-source jobs** (`job_name=<source system>`, e.g. `lucos_eolas`, `lucos_contacts`, `inference`, ontologies) — a per-source 403 is NOT swallowed and is NOT masked by the unconditional end-of-run `job_name="ingestor"` heartbeat (that's a separate "cron ran without crashing" signal). This is a DIFFERENT mechanism from the #702 `failed_item_ingest` check on the ingestor `/_info`, which covers the **per-item webhook** path ONLY (keyed on `_last_failure_at` set by `server.py._increment_failure`, self-clearing on clean reconcile). See [[pattern-arachne-eolas-dual-ingest-hyphen-pk]] and [[pattern-container-restart-log-buffer-artifact]].
