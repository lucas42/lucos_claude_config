---
name: project-schedule-tracker-v2-migration-expected-alerts
description: Expected (do-not-investigate) alert windows from the 2026-05-14/15 schedule_tracker v2 migration — for the 2026-05-15 ops checks pass
metadata:
  type: project
---

ADR-0004's "de-overload `system` field on schedule_tracker" shipped 2026-05-14 14:06 UTC through 2026-05-15 00:58 UTC. 12 caller services migrated from v1 (`system` only) to v2 (`{system, job_name}`); v1 `/report-status` now returns **410 Gone**; v1 synthetic rows purged.

**Why:** team-lead pre-briefed me 2026-05-15 evening so tomorrow's ops checks (2026-05-15 / 2026-05-16) don't waste investigation cycles on already-resolved alerts. Per the brief, no reply needed unless I spotted timeline errors — I didn't.

**How to apply:** During the next ops-checks pass, treat the following as expected and do NOT raise issues for them:

- **2026-05-14 ~15:04–15:35 UTC** — `lucos_arachne` cron alerts. Cause: v2.0.0 pythonclient's `/v2/` startup guard `sys.exit()`'d because `SCHEDULE_TRACKER_ENDPOINT` cred still pointed at v1 path. Resolved when lucas42 updated all 12 creds at ~15:35 UTC (lucos_creds#321, closed).
- **2026-05-14 22:30 UTC – 2026-05-15 00:21 UTC** — brief monitoring blips on any of the 11 remaining caller services as their deploys flipped them from v1 to v2 shape. Each clears on next successful tick.
- **2026-05-14 ~23:00 – 2026-05-15 ~00:21 UTC** — `lucos_media_import` service down on xwing. lucas42 deliberately stopped it during the slow `lucos/build` window to prevent it re-populating v1 rows the developer had just cleaned. Restarted ~00:21 UTC, currently healthy.
- **2026-05-15 ~00:30–00:50 UTC** — `lucos_monitoring` service restart on avalon (Loganne `deploySystem`/restart event). lucas42 restarted it to clear phantom systems left by v1 integration quirks.
- **From 2026-05-15 00:58 UTC onwards** — any **410 Gone** responses from schedule_tracker's `/report-status`. Expected — those are caught stragglers. Each carries a WARN log naming the User-Agent. v1 endpoint retired in `lucos_schedule_tracker#89`.

**What's still worth investigating if spotted:**

- A 410 + WARN-log User-Agent that doesn't map to any of the 12 known migrated services → a v1 caller none of us thought of. File an issue and flag the User-Agent.
- A v2 caller posting with empty `job_name` → would show up in `GET /jobs` (current count: 30 rows, all non-empty). File an issue against the offending service.

**Cross-references:**
- ADR: `lucos/docs/adr/0004-de-overload-system-field.md` (or similar — confirm number)
- 12 caller PRs by merge order: pythonclient #41 + #44; arachne #523; docker_health #89; backups #280; contacts_googlesync_import #182; creds #322; dns #90; media_metadata_api #233; media_weightings #225; repos #389; router #87; time #272; media_import #154; schedule_tracker #89 (v1 retirement).
- arachne v1-cleanup script tracked for removal in `lucos_arachne#528`.
- Build-time follow-up: `lucos_media_import#155` (slow `lucos/build` job — last to land at 00:20 UTC).

**Decay note:** This memory is one-shot — purpose is the 2026-05-15/16 ops-checks pass. Once that pass is done with no surprises, this can be archived/deleted. Don't carry the expected-alert windows forward indefinitely or they'll become false reassurance during unrelated future incidents.
