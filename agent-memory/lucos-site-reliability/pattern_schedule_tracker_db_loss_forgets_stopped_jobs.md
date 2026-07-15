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

## ⛔ `recreate_effort: automatic` STAYS — my change proposal was REJECTED, do not re-raise

I proposed `automatic` → `considerable` on lucos_backups#345. **lucas42 rejected it 2026-07-15** and he's right on his own definition: `recreate_effort` = *"what we'd do if we lost the volume **and were unable to restore from backup**"*. With the volume **and** all backups gone, spinning it back up and letting jobs report in genuinely is what we'd do. His risk arithmetic: it needs a job to permanently stop **+** catastrophic loss of the volume **+** unrecoverable loss of all backups across 3 servers — *"There is no scheduled job on our estate so critical that it deserves continuity planning so robust that it survives 5 separate critical failures."* Accepted risk. The mechanism above is still true; it just doesn't justify changing the field.

**The defect I found was real but I aimed it at the wrong artifact** (team-lead spotted this, 2026-07-15). The hazard isn't the field's *value* — it's `restore-runbook.md`'s *use* of it: it names this volume and tells the operator to *"Check `config.yaml` for the `recreate_effort` value before deciding whether to restore from backup or just restart the service and let it rebuild"*. That uses the field to decide whether to bother with a backup we **still have**, which is **not what lucas42 says it's for** — so in practice the chain is 2 failures, not 3 (job stops → volume lost → operator reads `automatic`, skips a *working* restore). This applies to **all 11 volumes** that runbook section covers; `lucos_creds_store`'s bespoke "Always restore from backup" note is the same patch applied one volume at a time. Put to lucas42 2026-07-15 — **if he declines, drop it; do not relitigate via the field value.**

**Operational consequences (unchanged, and independent of the above):**
- **Never** wipe/recreate this volume as a casual remediation. Treat it as stateful, not a cache.
- **If you have a backup, restore it** — don't let `automatic` talk you out of a restore you can actually perform. That's the field being read outside its definition.
- It **must keep its backup**, and therefore must keep `quiesce: true` in lucos_backups#344's rollout (so #344 goes 8→7 if repos_data is skipped, not 8→6).
- After any loss, there is **no self-heal for the broken jobs** — you'd have to reconcile expected jobs from another source (monitoring reads *from* schedule_tracker, not the reverse — see [[pattern_monitoring_coverage_http_vs_scheduled]] — so it can't backfill).

Related: [[reference_schedule_tracker_detection_semantics]] (ADR-0004: red needs 2 consecutive fails), [[project_backups_db_consistency_walkback]].
