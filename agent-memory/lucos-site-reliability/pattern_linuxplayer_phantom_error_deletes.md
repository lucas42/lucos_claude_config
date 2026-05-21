---
name: pattern-linuxplayer-phantom-error-deletes
description: Until lucos_media_linuxplayer#123 ships, watch for ?action=error DELETE floods on ceol from linuxplayer hosts
metadata:
  type: project
---

`lucos_media_linuxplayer` has a phantom-retry bug: it keeps firing `DELETE …/playlist/null/{uuid}?action=error` to ceol for tracks the player has already advanced past. Filed as **[`lucas42/lucos_media_linuxplayer#123`](https://github.com/lucas42/lucos_media_linuxplayer/issues/123)** on 2026-05-21.

**Why:** On 2026-05-21 14:44:30 UTC a single linuxplayer on `xwing-v4.s.l42.eu` produced 2,714 such DELETEs in ~5 minutes, peaking at 145 req/s. This saturated loganne's outbound webhook fan-out and triggered the `webhook-error-rate` alert. The player itself was healthy throughout — it had advanced through three tracks while the DELETE storm was hitting ceol for the *previous* tracks' UUIDs.

**How to apply:** During ops checks or incident investigation, if `loganne/webhook-error-rate` is firing with `trackUpdated ... errored` events as the trigger, AND the access log on avalon's `lucos_router` shows a burst of `DELETE /v3/playlist/null/<uuid>?action=error` calls from a `lucos_media_linuxplayer/<host>` user-agent — that's recurrence of #123, not a new bug. Same remediation: retry the stranded webhooks via `POST /events/retry-webhooks` (auth: `KEY_LUCOS_LOGANNE`), confirm the alert clears, note the recurrence on #123 if useful, move on. **Don't file a duplicate ticket.**

The repeating signature:
- Same playlist UUID across hundreds of DELETEs in a short window
- `User-Agent: lucos_media_linuxplayer/<host>`
- All return 204 (the request itself is fine)
- The player is simultaneously sending `PUT /v3/playlist/null/<different-uuid>/current-time` for a newer track UUID

Related: [[loganne-webhook-retry-api]] (cleanup), [[pattern-access-log-first-for-webhook-bursts]] (diagnostic order).
