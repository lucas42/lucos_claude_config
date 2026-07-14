---
name: schedule-tracker-db-loss-forgets-stopped-jobs
description: Losing lucos_schedule_tracker_db silently and PERMANENTLY erases exactly the stopped jobs it exists to detect — healthy jobs re-register, broken ones never do, board goes green
metadata:
  type: reference
---

**`lucos_schedule_tracker` has NO job registry.** No configy load, no static list, no seed. The only way it learns a job exists is that job POSTing `/v2/report-status`, and the expected **`frequency` is a required field supplied by the reporting job itself** (`src/server.rb:122` → `INSERT OR REPLACE INTO schedule(system, job_name, frequency, …)`; README v2 API schema confirms). Verified 2026-07-14.

**Therefore, if `lucos_schedule_tracker_db` is lost/wiped/recreated:**
- **Healthy** job → re-registers on its next run. Blind window ≤ that job's frequency. Recovers.
- **Already-stopped** job → never POSTs → **never re-registers** → tracker cannot know it was ever expected → **can never alert on it. Permanently.**

The service's whole purpose is detecting stopped jobs. So DB loss **silently erases exactly the failures it exists to catch**, while healthy jobs re-register and paint the board **green**. Green not because things are healthy — because it has forgotten what it was watching. Strictly worse than the volume being empty and obviously broken.

**⚠️ The hazard is LIVE and operationalised in the runbook.** `lucos_backups/docs/restore-runbook.md` lists `lucos_schedule_tracker_db` **by name** and tells the mid-incident operator: *"Check `config.yaml` for the `recreate_effort` value before deciding whether to restore from backup or just restart the service and let it rebuild."* Reading `automatic` there → operator correctly concludes "let it rebuild" → **silently destroys estate-wide stopped-job detection, with a good backup sitting unused.** Under lucas42's semantics ([[reference_recreate_effort_vs_skip_backup_semantics]]) `automatic` literally *means* "make no manual attempt to restore, let it repopulate" — i.e. the field is an instruction to do the destructive thing.

**Operational consequences:**
- **Never** wipe/recreate this volume as a casual remediation, and **never follow the runbook's rebuild path for it**. Treat it as stateful, not a cache.
- `recreate_effort: automatic` in configy `volumes.yaml` is **WRONG** → should be **`considerable`** (manual recreate = enumerate every scheduled job across ~30 repos with **no canonical list to check completeness against**; not `tolerable` — the loss is silent and disables detection). Proposed on lucos_backups#345 + a runbook override note like `lucos_creds_store`'s "always restore from backup".
- It **must keep its backup**, and therefore must keep `quiesce: true` in lucos_backups#344's rollout (so #344 goes 8→7 if repos_data is skipped, not 8→6).
- After any loss, there is **no self-heal for the broken jobs** — you'd have to reconcile expected jobs from another source (monitoring reads *from* schedule_tracker, not the reverse — see [[pattern_monitoring_coverage_http_vs_scheduled]] — so it can't backfill).

Related: [[reference_schedule_tracker_detection_semantics]] (ADR-0004: red needs 2 consecutive fails), [[project_backups_db_consistency_walkback]].
