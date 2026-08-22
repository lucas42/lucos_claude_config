---
name: pattern-failthreshold-counts-source-updates
description: lucos_monitoring's failThreshold increments per source update, not per failing poll, so failThreshold=2 fires on ONE bad reading on any multi-source system (lucos_monitoring#303)
metadata:
  type: project
---

`failThreshold` does **not** mean "N consecutive failed polls". `applyFailThreshold/2`
(`src/monitoring_state_server.erl`, ~L386) increments `consecutiveFailsCount` for every
check with `ok: false` in the **merged** check map, on **every** `updateSystem` cast —
from any source. `mergeSourceChecks/1` carries each non-reporting source's last payload
verbatim, so a single failure reported by `info` is counted again the moment
`circleci` / `ports` / `scheduled_jobs` next reports. On a multi-source system
`failThreshold: 2` therefore fires on **one** bad reading.

Filed as lucas42/lucos_monitoring#303 (2026-08-22).

**Why:** the estate's primary anti-flap tool is doing much less than its declarations
imply — live on `lucos_media_seinn` (2), `lucos_media_metadata_manager` (3),
`lucos_media_manager` (3/2), `lucos_backups` (5), plus the synthetic `fetch-info` /
`tls-certificate` probes. Effective threshold silently depends on how many sources a
system happens to have. Exact precedent: **#155 fixed this identical bug for
`unknown_count`** via `CountableKeys` (L98); the FailsGate never got the guard.
`CountableKeys` is narrowed to `ok=unknown` keys, so the fix needs a *second, wider*
set (`maps:keys(SourceChecks)`).

**How to apply:**
- Never conclude "this alert means N consecutive failures" from a `failThreshold`
  declaration. Check whether the alert timestamp sits *between* `/_info` polls.
- Do not respond to a flap by bumping `failThreshold` until #303 lands — that is the
  workaround #155 explicitly rejected, and it punishes single-source systems.
- Proof pattern worth reusing: read the **router access log** for the system's
  `/_info` polls (UA `lucos_monitoring`, once per minute at a fixed second). An alert
  landing between two polls cannot be a second failing reading. Free bonus control —
  a failing `/_info` is *larger* than a healthy one (the extra `debug` field), so
  response byte counts alone distinguish the readings (seinn: 367 vs 315).
- All four fetchers loop on `timer:sleep(timer:seconds(60))` from boot, so per-system
  phase offsets are arbitrary and drift. This is why the bug shows up as occasional
  flap rather than constant noise — and why `lucos_backups` never alerts on its hourly
  `:07` `/_info` blackout despite `failThreshold: 2`: monitoring polls it at `:40`/`:47`
  and simply never sees the failure. See [[pattern_dependson_deploy_window_only]] and
  [[feedback_failthreshold_lives_in_info]].
