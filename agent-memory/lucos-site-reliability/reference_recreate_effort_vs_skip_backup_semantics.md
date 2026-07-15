---
name: recreate-effort-vs-skip-backup-semantics
description: lucas42's authoritative semantics for configy's recreate_effort and skip_backup — independent fields, neither inferred from the other; recreate_effort drives a live restore-runbook decision
metadata:
  type: reference
---

lucas42's definitions (lucos_backups#345, 2026-07-14), verbatim:

> `recreate_effort` is for flagging what we'd do if we lost the volume and were unable to restore from backup. If the value is `automatic`, then that means "we'd make no manual attempt to restore the data, just leave systems to run their course to repopulate it".
> `skip_backup` is for flagging that there's no value in backing up a given volume.
> One doesn't necessarily follow from the other. There's many reason why we may still want a backup for something which can be repopulated automatically.

**The three reasons to back up something that repopulates automatically** (his, use as the per-volume test):
1. **Edge cases the repopulation misses.**
2. **Repopulation slow enough that a restore is quicker.**
3. **Repopulation hits rate limits at source.**

**Do NOT infer one field from the other**, and don't propose a convention that does. I pattern-matched "9 of 15 `automatic` volumes lack `skip_backup`" into an inconsistency and helped inflate it into a policy question; lucas42 rejected the premise and asked *"What's the problem we're trying to solve?"* — there wasn't one. See [[feedback_ask_what_problem_before_accepting_scope]].

**`recreate_effort` is not a label — it drives a live decision.** `lucos_backups/docs/restore-runbook.md` tells the mid-incident operator to check `recreate_effort` "before deciding whether to restore from backup or just restart the service and let it rebuild". So a wrong value causes the wrong restore action at the worst moment. `lucos_creds_store` gets an explicit "always restore from backup" override note there.

**Vocabulary** (`lucos_backups/src/effort_labels.yaml` — validated; an invalid value warns + falls back to `unknown`, see [[pattern_backups_invalid_effort_crashes_host_tracking]]):
`small` (Small Technical Effort) · `considerable` (Considerable Effort) · `huge` (Huge Effort) · `automatic` (Fully Automated) · `tolerable` (Tolerable Loss) · `remote` (Remote Mount From Elsewhere) · `unknown` (Unknown Effort)

**Worked contrast** — two volumes both describable as "regenerable job state", landing opposite. No pattern-matching separates them; only per-volume analysis does:

| | `lucos_photos_redis_data` | `lucos_schedule_tracker_db` |
|---|---|---|
| Holds | transient queue | **the authoritative state itself** |
| Truth elsewhere? | ✅ Postgres (backed up + quiesced) | ❌ nowhere — no registry |
| Reconcile? | ✅ `worker/app/main.py` `sweep_pending_photos()`, 60s, re-enqueues `pending`/`processing` from Postgres | ❌ none |
| Verdict | `automatic` ✅ + `skip_backup: true` (approved 2026-07-15) | `automatic` ✅ **stays** + keep backup — my `considerable` proposal was **REJECTED**, don't re-raise ([[pattern_schedule_tracker_db_loss_forgets_stopped_jobs]]) |

**The contrast still holds and is still the point** — both are describable as "regenerable job state" yet differ in every structural respect, which is *why* no inference rule can separate them. But note the trap I fell into: I read "repopulation misses the stopped jobs" as proving the field's value wrong. It doesn't. The field only speaks to the **no-backups-left** case, where letting them repopulate genuinely is what we'd do. **Check which case a field is defined for before calling its value wrong.**
