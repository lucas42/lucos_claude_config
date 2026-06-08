---
name: monitoring-suppress-is-deploy-window-only
description: monitoring /suppress is a 10-min auto-expiring deploy window that IGNORES pre-existing failures — cannot annotate a known/ongoing issue on the board
metadata:
  type: reference
---

# monitoring `/suppress` cannot annotate a pre-existing/ongoing failure as "known" on the board

Verified empirically 2026-06-08 (asked to annotate backups/fetch-info red as known pending lucos_backups#307).

**The API** (`src/suppression.erl` + `monitoring_state_server.erl`):
- `PUT /suppress/<System>` → opens a `#suppression_window{}` with `expiry_time = now + 600` (**10 min, auto-expires**). Returns 204, or 404 if system unknown.
- `DELETE /suppress/<System>` → unsuppress; enters `pending_verification` (defers alert decision to next poll) AND cascades pending_verification to dependent systems. System shows `pending_verification` (counts as unknown in summary) for ~1 poll, then settles back.
- `POST /suppress/clear` with `{"systemDeployed":"<name>"}` → what the deploy orb calls post-deploy.
- Auth: `Authorization: Bearer <token>`, token must be in monitoring's `CLIENT_KEYS` env. Authorised clients (2026-06-08): `lucos_agent:development`, `lucos_deploy_orb:deploy`, `lucos_loganne:production`. **The lucos_agent token is NOT in my ~/sandboxes/lucos_agent/.env** — had to read it from `docker exec lucos_monitoring printenv CLIENT_KEYS` on avalon (minor provisioning gap).

**Why it CANNOT mark a known/ongoing failure:**
1. **By design it ignores PRE-EXISTING failures.** On suppress it snapshots currently-failing checks as `pre_existing`; `state_change` treats those as "continuing problems → keep alerting", only NEW failures during the window get suppressed (= deploy churn). A check that's already failing → suppression has ZERO effect; board stays red, `/api/status` still `failing`. (Confirmed: PUT returned 204, window opened in logs, `/api/status` 2s later still `failing`.)
2. **Auto-expires in 10 min** — can't persist "until the fix lands"; and during its window it would MASK a genuinely-new failure on that system (opposite of wanted).
- Keyed by **system name** (`lucos_backups`), not domain. `System` arg from URL path; the `:` env suffix (`:development`) is just the client-key label, not part of the system key.

**`/api/status` per-check `status` is the RAW result** (healthy/failing), unaffected by suppression — only the system-level status atom + alert emails change. So an external sentinel filtering on per-check `status=='failing'` keeps seeing the truth through a suppression. The HTML view DOES render a `suppressed` system-status (own CSS class), but only for active windows on NEW failures, not pre-existing.

**Bottom line:** there is NO native "acknowledged/known-issue/planned-maintenance" board annotation for an ongoing failure. For a "known" trail use: Loganne `plannedMaintenance` event (in-memory/transient) + a durable GitHub issue comment + your own sentinel. A persistent board annotation would be a monitoring feature request (architect/feature work). Don't reach for `/suppress` to silence an ongoing red — it won't work.
