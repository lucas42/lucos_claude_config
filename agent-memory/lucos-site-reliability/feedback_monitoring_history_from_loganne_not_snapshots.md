---
name: feedback-monitoring-history-from-loganne-not-snapshots
description: To establish how LONG a monitoring check was red/green (duration/history claims), use the loganne monitoringAlert/monitoringRecovery event record — NOT point-in-time /api/status snapshots, which show only current state and lie about duration
metadata:
  type: feedback
---

**Rule:** any claim about the *history* or *duration* of a monitoring check's state ("green throughout the outage", "red for 2 days", "never went red") MUST come from the **loganne event record** (`monitoringAlert` / `monitoringRecovery` events), not from `monitoring.l42.eu/api/status` snapshots.

**Why:** `/api/status` is a point-in-time snapshot — it shows the check's state *right now*. Sampling it a few times during an incident and concluding "it was green the whole time" is invalid: you can't see the flaps, the alerts that fired and recovered, or the actual red/green timeline between your samples. loganne's `monitoringAlert`/`monitoringRecovery` events ARE that timeline, timestamped and authoritative.

**How:** `curl -H "Authorization: Bearer $KEY_LUCOS_LOGANNE" "https://loganne.l42.eu/events?limit=N"`, filter to `type` in {`monitoringAlert`, `monitoringRecovery`} and the system in `humanReadable`. `deploySystem` events in the same feed pin version/deploy times (e.g. `Deployed lucos_creds v1.3.81 to avalon`). Key in `~/sandboxes/lucos_agent/.env` as `KEY_LUCOS_LOGANNE`.

**Grounding (a real mistake):** 2026-07-19→22, lucas42/lucos_creds#474. I asserted the `configy_sync` check was "green throughout / structurally blind for 2.5 days" from `/api/status` snapshots, filed lucas42/lucos_schedule_tracker#96 on that thesis, and wrote it into the incident report. The loganne record showed the exact opposite: configy_sync fired alerts repeatedly across 3 days — monitoring CAUGHT the outage — and the real gap was a ~69-min false-*recovery*, a completely different (and narrower) finding. lucas42 caught it via loganne. I already had [[reference-loganne-read-self-verify]] but applied it only to cred/deploy self-verification, not to monitoring-duration claims. Extends that rule. Related: [[reference-schedule-tracker-detection-semantics]], [[feedback-verify-root-cause-by-reproduction]].
