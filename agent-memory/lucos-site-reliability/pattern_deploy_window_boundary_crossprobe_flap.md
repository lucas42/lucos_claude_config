---
name: pattern-deploy-window-boundary-crossprobe-flap
description: Cross-service probes with correct dependsOn STILL flap during coordinated multi-service deploys because the dependency is unreachable before its own deploy-window opens
metadata:
  type: project
---

Cross-service probe checks that already declare `dependsOn: lucos_media_metadata_api` (weightings `media-api-reachable`, metadata-manager `metadata-api`) STILL fire real `monitoringAlert` events (NOT `monitoringAlertSuppressed`) during a coordinated multi-service media rollout.

**Why:** `dependsOn` suppresses a dependent's check ONLY while the depended-on system is inside its own deploy window. During a coordinated rollout the dependency (media-api) is briefly unreachable as its container is torn down BEFORE its deploy-window suppression opens (its `deploySystem` event registers ~1 min after the container actually goes down). The dependent's probe polls it in that gap. Tell: dependent's alert timestamp is ~1 min BEFORE the dependency's `deploySystem` event; recovery within 1–3 min; zero `monitoringAlertSuppressed` events in the window.

**How to apply:** When ops-check Check 2 surfaces brief weightings/metadata-manager cross-probe flaps clustered around a burst of media-stack deploys (5 deploys in ~3 min), this is the boundary-gap pattern — NOT a new incident, NOT a missing dependsOn (it's already there). Don't re-diagnose. Tracked + impact/effort framing in lucas42/lucos_monitoring#286 (P3, filed 2026-06-15). Candidate fix = `failThreshold: 2` on the cross-probes (cheap, rides out a single-poll gap); root-cause fix (pre-deploy suppression in the orb) is estate-wide blast radius and likely not worth it. First diagnosed 2026-06-14 cluster. Related: [[pattern_dependson_deploy_window_only]].
