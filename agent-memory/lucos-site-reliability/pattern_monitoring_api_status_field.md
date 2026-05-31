---
name: pattern-monitoring-api-status-field
description: monitoring.l42.eu/api/status checks use a `status` string field, NOT an `ok` boolean — parsing for `ok` returns all-None and looks like a false "everything unknown" alarm
metadata:
  type: reference
---

`https://monitoring.l42.eu/api/status` shape:
- top-level: `{systems: {name: {...}}, summary: {healthy, failing, unknown, total_systems}}`
- per check: `{status: "healthy"|"failing"|"buffering", statusText, techDetail, link}` — **`status` string, not `ok` boolean**. (The per-service `/_info` endpoints DO use `ok` booleans — don't confuse the two.)

`buffering` / `statusText: "unknown (N)"` = the check is mid-`failThreshold` (N consecutive fails so far, not yet alerting). Post-deploy cold-state shows here transiently.

Use `summary` for the authoritative count. Bit me 2026-05-31: my ad-hoc parser read `c.get('ok')`, got None for all 196 checks, and briefly looked like a total monitoring blackout when the estate was actually 50/51 green.
