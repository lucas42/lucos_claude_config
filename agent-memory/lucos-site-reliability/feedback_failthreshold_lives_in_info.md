---
name: failThreshold lives in /_info, not lucos_monitoring
description: Per-system check thresholds (failThreshold, etc.) are declared by each service in its /_info response — lucos_monitoring holds no system-specific config
type: feedback
---

System-specific check thresholds (failThreshold and any equivalents) belong in the service's `/_info` response, not in lucos_monitoring config. lucos_monitoring is generic — it holds no system-specific logic.

**Why:** lucas42 corrected this 2026-05-05 when I proposed raising a `failThreshold` issue against lucos_monitoring. Quoting: "the failThreshold config comes from the /_info endpoint, so it'll need to be raised against [the service] - we don't hold any system-specific logic in lucos_monitoring." Architectural rule: each system owns config that's specific to its own checks.

**How to apply:** When proposing changes to per-check thresholds, check suppression behaviour, or any per-system tuning of monitoring sensitivity, raise the issue against the **service repo** (whose `/_info` declares the check) — not against lucos_monitoring.

**Exception — monitoring-generated synthetic checks:** Three checks are NOT declared by services; lucos_monitoring stamps them onto every system itself: `fetch-info` and `tls-certificate` (in `src/fetcher_info.erl` lines 43-46) and `circleci` (in `src/fetcher_circleci.erl`). For these three names, `failThreshold` IS configured inside lucos_monitoring — the in-file precedent is the existing `maps:put(<<"failThreshold">>, 2, ...)` pattern. PR lucos_monitoring#195 added it for fetch-info/tls-certificate; the same shape applies to circleci (issue #226 2026-05-12).

**The pre-filing check — DO NOT SKIP:** Before drafting any "raise failThreshold on `X-check`" issue, run both of these:

1. `curl -s https://<service>.l42.eu/_info | jq '.checks | keys'` — does the service declare it?
2. `grep -n '<<\"X-check\">>' ~/sandboxes/lucos_monitoring/src/fetcher_*.erl` — does monitoring synthesise it?

If (1) is yes → file on the service repo. If (2) is yes and (1) is no → file on `lucos_monitoring` and cite the existing `fetcher_info.erl` precedent. If both are no, you've misnamed something. Skipping this on 2026-05-12 led to lucos_monitoring#226 getting rejected with "completely misunderstands the model" — the original body conflated the two populations and falsely implied services could override the circleci check.

**Related fix-shape rule:** When a service-specific check is flapping during a known-good transient state, the cleanest fix is usually inside the service's `/_info` handler — refining the check's `ok` semantics so that the transient state isn't reported as a fault in the first place. Example (lucos_media_manager#239): `empty-queue` reports `ok: true` while a fetcher thread is alive, because "queue is empty but being repopulated" is intended behaviour. Smaller diff than tweaking thresholds, doesn't mask real faults.
