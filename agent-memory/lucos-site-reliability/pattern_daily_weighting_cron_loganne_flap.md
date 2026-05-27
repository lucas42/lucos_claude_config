---
name: pattern-daily-weighting-cron-loganne-flap
description: Daily 02:00-02:30Z UTC bulk track-weighting recompute saturates loganne event loop, producing 1-2 event-loop-lag-low flaps per day. Known cause; remediation TBD.
metadata:
  type: project
---

## Pattern

`lucos_media_weightings` runs a daily bulk track-weighting recompute around **02:00-02:30Z UTC** that emits ~220 `trackWeightingUpdated` events through `lucos_media_metadata_api` → `lucos_loganne`. Fanning those out to 3 webhook subscribers each (`ceol`, `arachne`, `media-weighting`) produces ~660 outbound webhook fires concentrated in ~30 min.

This is enough to push loganne's `event-loop-lag-low` p99 over its 1500 ms threshold (post-#493 tuning) briefly. Observed signature:

- 1-2 `monitoringAlert: event-loop-lag-low` events between 02:13Z and 02:25Z
- Each recovers within ~1 minute
- Occurs daily — confirmed 2026-05-24, 2026-05-25, 2026-05-26

## Why this isn't filed as a ticket yet

Calibration check (per persona's [[calibrating-follow-up-issue-proposals]]):

- **Failure-mode impact**: 1-2 brief alerts/day at 02:13-02:25Z UTC; phone buzz; no cascade
- **Available remediations don't fit cleanly**:
  - `dependsOn` suppresses only during deploy windows, not arbitrary cron windows
  - `failThreshold` already at 2 from #484
  - Bumping the 1500 ms p99 threshold further trades sensitivity for daily-known noise
  - Designing a new "scheduled-job suppression" mechanism on lucos_monitoring is a feature, not a bug fix
- **Honest comparison**: filing without a clear small actionable fix wastes triage cycles. The check is doing its job — telling us loganne is briefly saturated during the daily cron — and the team has the post-#493 calibration data fresh.

## Why: link to source

The daily cron is in `lucos_media_weightings`. trackWeightingUpdated events confirmed via Loganne lookback (2026-05-26 02:00-02:30Z window: 224 trackWeightingUpdated events from `lucos_media_metadata_api`).

## How to apply

When seeing 1-2 `lucos_loganne event-loop-lag-low` flaps in the **02:13-02:25Z UTC** window during ops checks:

1. Do NOT diagnose root cause again — it's the daily weighting recompute.
2. Do NOT file a new ticket — the recurrence is calibrated, not actionable.
3. DO count them in the completion manifest as "known daily cron-induced flaps".

If the **count rises** (≥4/day, or spread outside the 02:00-02:30Z window in a way that suggests a different driver), revisit. Possible next step would be a proposal on `lucos_monitoring` for a `dependsOn-job` mechanism, or moving the bulk recompute to a paced async fan-out instead of a burst.

Related: [[pattern-arachne-preflabel-makes-indexable]] (unrelated, just another known recurring saturator). Closed by [[lucos_loganne#493]] threshold tuning was the right fix for the *acute* sensitivity issue — this is the residual baseline noise from a real-but-brief daily saturation event.
