---
name: pattern-dependson-deploy-window-only
description: monitoring's dependsOn suppression covers ONLY the upstream's deploy window, not arbitrary outages — weigh this before proposing any dependsOn edge
metadata:
  type: reference
---

**`dependsOn` in `lucos_monitoring` suppresses a failing check ONLY while the depended-on system is in its DEPLOY window** (plus a single `pending_verification` grace poll after the window closes). It does **not** suppress during arbitrary (non-deploy) outages of the upstream.

- Suppression map is populated only by the `{suppress, System}` cast = the `/suppress` endpoint, driven by deploy windows (`lucos_monitoring/src/monitoring_state_server.erl:228–250`). Cascade-after-window-close at `:266–270` (`find_dependent_systems`). Single-hop only (ADR-0002).
- So the ONLY value of declaring `dependsOn: X` on a check is "don't false-alert this check while X is being deployed." If the check can't even go red within a minutes-long deploy window, the edge buys nothing.

**Corollary — schedule_tracker job checks are lagging/threshold-based**, so they rarely benefit from `dependsOn`. A job's check goes red only after `error_threshold` consecutive failures OR `time_threshold` since last success (`lucos_schedule_tracker/src/database.rb`): frequency ≥ 90min → threshold 2, time ≈ freq×2+30min. A **daily** job needs ~2 days of failures to alert — it can never trip during a deploy window, so a `dependsOn` edge on it is worthless.

**schedule_tracker check model:** jobs report via `/v2/report-status` (system, frequency, status, job_name, message). schedule_tracker derives `{techDetail, ok, debug}` server-side and exposes per-job entries at `/jobs`. monitoring's `fetcher_scheduled_jobs` polls `/jobs`, reads the `check` map **verbatim**, and attributes it to the job's `system` (so `reconcile_tag_names` shows under `lucos_media_metadata_api`, not under schedule_tracker). There is **no `depends_on` column/field** in `schedule_v3` — adding one would be a shared-infra schema change.

**Where this came from:** lucos_media_metadata_api#299 (closed not-planned 2026-06-01, lucas42 accepted the latent gap). I'd filed it proposing an eolas dependsOn edge; investigation showed the only home (reconcile_tag_names, daily) couldn't benefit, and an always-on `/_info` eolas-reachable check would over-alert media_metadata_api on real eolas outages (eolas is only its write-path dep). Lesson: trace what dependsOn actually suppresses before proposing the edge. See [[feedback_failthreshold_lives_in_info]].
