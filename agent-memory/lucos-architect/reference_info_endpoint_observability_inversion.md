---
name: info-endpoint-observability-inversion
description: Recurring estate pattern — a service's /_info cost scales with its own workload, so it reports itself unhealthy exactly when busy; three instances, tracked as lucos#288
metadata:
  type: reference
---

**Pattern: `/_info` generation whose cost is a function of the service's own workload.** The endpoint blows the 1s poll budget for a window, monitoring reports the service degraded, nothing is actually wrong. The signal inverts: the busier the system, the less able it is to say it is fine.

Three confirmed instances (2026-08-09):

- **lucos_monitoring#298** — `/_info` served by the same `gen_server` that ingests every check result. Each `updateSystem` cast synchronously renders the full dashboard HTML for all systems inside the state server's process. `/_info` also makes *two* `gen_server:call`s, so it queues twice.
- **lucos_backups** — `Tracking Backups...` runs at HH:07:00; `/_info` exceeds budget while it does.
- **lucos_media_weightings#277** — two `dependsOn` upstream probes at 1.0s timeout each; alerted *weightings* as unreachable 7 min before the actually-down `lucos_time`.

**Rule now tracked for the canonical spec at lucas42/lucos#288** (deliberately kept separate from lucos#283, which only migrates already-agreed orphaned rules — a new rule riding in on a reconciliation ticket gains unearned authority).

**Diagnostic worth reusing:** if only *one* service shows a symptom, ask what is structurally unique about it. Monitoring was the only service whose `/_info` latency depended on its own workload — every other service generates `/_info` in a process unrelated to its work.

**Second reusable finding (lucos_monitoring, likely generalises):** all four fetchers spawn one process per target in a tight `lists:foreach` then `timer:sleep(60s)` — no jitter, no stagger. A phase-aligned thundering herd at container start, which then slowly spreads as each poller's true period is `60s + its own duration`. Explains both a tight burst and its decay over hours after a restart. Check for missing stagger whenever a periodic-poller fleet shows bursty load.

Related: [[docker-healthy-not-reachability]], [[convention-catalogue]].
