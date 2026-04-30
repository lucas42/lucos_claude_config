---
name: Don't accept flaps as "expected" or "known pattern"
description: When ops checks find flaps, use suppression tools (dependsOn / failThreshold / deploy-window) or file a ticket — never tolerate noise
type: feedback
---

When Check 2 surfaces a flap (any `monitoringAlert`/`monitoringRecovery` cycle), do not write it off as "expected", "known pattern", "deploy-storm noise", or similar. The presence of an alert means we crossed a threshold designed to wake people up — accepting that as routine erodes the value of every alert.

**Why:** lucas42 raised this 2026-04-30 after I dismissed two findings during ops checks: (a) the lucos_photos midnight db+redis blip with "container has been restarted, logs gone — not enough to file" and (b) the morning estate deploy storm flapping on media-weightings/media-api as "known dependency-chain pattern". Neither was the right response. The right response is to use the tools we already have — and add new ones if they're insufficient.

**How to apply:**

The lucos monitoring service supports four flap-mitigation mechanisms. When a flap is genuinely acceptable, use one of them — don't tolerate it:

1. **Deploy-window suppression** (automatic): alerts on a deploying system are suppressed during its deploy window. Already on by default for the deploying system itself.

2. **`dependsOn`** (declare in `/_info` payload): a check declared `dependsOn: <other_system>` is suppressed when the depended-on system is in its deploy window. This is the fix for cross-service probes that flap during dependency deploys (e.g. weightings.media-api-reachable during a media-api deploy). Already in use on `lucos_media_seinn` (`media-manager` check `dependsOn: lucos_media_manager`). Adding it to a flapping check is usually a one-line `/_info` payload change.

3. **`failThreshold`** (declare in `/_info` payload, integer ≥ 1, default 1): number of consecutive failed polls required before alerting. Use to ride out tight-timeout transients. Already in use on weightings (both checks have `failThreshold: 2`) and after `lucos_monitoring#195` for `fetch-info` and `tls-certificate`.

4. **Warm-up alert skipping** (built into `lucos_monitoring`): `lucos_monitoring` skips alerts on the first poll after its own restart so its cold-state cache misses don't cascade. Don't need to do anything to use this.

If none of these fit the pattern, **raise a ticket on `lucos_monitoring`** proposing a new mechanism (or extension). "We've seen this before" is not a disposition.

If you can't diagnose because logs are gone or the container's been replaced, **the next step is to add more logs**, not to give up. File a small issue on the affected service requesting diagnostic logging around the failing check.
