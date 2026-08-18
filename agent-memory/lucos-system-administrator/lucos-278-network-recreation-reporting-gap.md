---
name: lucos-278-network-recreation-reporting-gap
description: lucos#278 network recreations both succeeded but sat unreported 9 days; step 2 (six NODE_OPTIONS PRs) never started
metadata:
  type: project
---

lucos#278 (Node Happy Eyeballs amplification fix): step 1 (recreate `lucos_time_default`, `lucos_monitoring_default` on avalon, `lucos_dns_secondary_default` on xwing so already-merged `enable_ipv6: true` takes effect) finished 2026-08-09 — `lucos_time` hit a subnet collision and needed a hotfix (lucas42/lucos_time#351/#352, resolved), but xwing and avalon monitoring both succeeded cleanly. Neither success was ever posted back to the tracking issue; it sat with its last comment from 2026-08-08 for 9 days looking stalled. Posted the catch-up comment 2026-08-18.

**Why:** completed operational work that needed no rollback is easy to consider "done" without closing the loop on its tracking issue — but a quiet issue with no rollback event looks identical to a stalled one from the outside, and this one genuinely had an unstarted half.

**How to apply:** always post a result comment on the tracking issue when operational work finishes, even (especially) when nothing went wrong — "no news" reads as "no progress" to anyone else watching the issue.

**Still open:** step 2 — `NODE_OPTIONS=--network-family-autoselection-attempt-timeout=3000` on `lucos_time`, `lucos_media_seinn`, `lucos_media_linuxplayer`, `lucos_authentication`, `lucos_loganne`, `lucos_notes` — was never started (verified 2026-08-18, zero of six carry it). One PR per repo; value and audit already settled, needs dispatch.

See also [[commit-claude-main-delete-support]].
