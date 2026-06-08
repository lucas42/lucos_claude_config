---
name: pattern-monitoring-realert-per-deploy
description: Repeated monitoringAlerts for the SAME continuously-failing check = one re-alert per deploy of that service ("still unhealthy after deploy"), not a flapping check
metadata:
  type: project
---

# Repeated alerts for a static failing check = one re-alert per deploy

Symptom (2026-06-08, lucos_backups create-backups): user saw many
"1 failing check on lucos backups" emails for the SAME check while nothing about
the check changed. Loganne showed ~5 `monitoringAlert` events with **zero
`monitoringRecovery` between them** (only one real recovery at the end) — so it was
NOT ok→fail flapping.

**Root cause:** each `deploySystem` of the service re-fires the alert. The deploy orb
opens a monitoring **suppression window**; when it closes, monitoring enters
`pending_verification` and waits for fresh post-deploy data, then in
`monitoring_state_server.erl` (~line 131):
`logger:notice("Service ~p still unhealthy after deploy — alerting")` →
`notify_all(...)` whenever `maps:size(FailingNow) > 0`. So **if the service is still
failing after a deploy, monitoring emits a fresh alert — once per deploy**, regardless
of the sticky per-episode `Alerted` flag. By design (intent: "your deploy didn't fix
the known problem"). Refs ADR-0003, issues #252/#264 (suppression asymmetry).

**Why it was noisy that day:** lucos_backups was deployed 5× in ~3h iterating the #309
fix (v1.1.0→v1.1.4). Each deploy → one "still unhealthy after deploy" create-backups
alert ~40–60s later (after the post-deploy verification poll). 1:1 with the deploys.

**Diagnostic recipe:**
1. Pull Loganne `monitoringAlert`/`monitoringRecovery` for the system (time field is
   **`date`**, not `time`; filters are client-side — see [[reference_loganne_read_self_verify]]).
2. If many alerts with no recoveries between → not flapping; look for repeated deploys.
3. Pull `deploySystem` events (note: their `system` field is often `None` — match on
   `humanReadable` "Deployed lucos_X vN to host"). Correlate timestamps: alert ~1 min
   after each deploy = this pattern.
4. The transient `count=2` variants (`+fetch-info`, `+host-tracking-failures`) are just
   checks blipping during the container restart; the constant check is the real one.

**Verdict:** working as designed; amplified by rapid redeploys of a knowingly-broken
service. Not a bug. Possible refinement (only if fix-cycle noise is judged too high):
suppress the post-deploy re-alert when `FailingNow ⊆ pre-deploy failing set` — i.e.
re-alert only when a deploy *introduces* a new failing check. Touches delicate
suppression logic; don't change reflexively. Related: [[pattern_monitoring_suppression_asymmetry]],
[[pattern_dependson_deploy_window_only]].
