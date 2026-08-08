---
name: monitoring-dependent-failure-grouping
description: Implementation trap for lucos_monitoring#296 (dependent-failure grouping) — key on system-level dependsOn, not the failing check's
metadata:
  type: project
---

`lucas42/lucos_monitoring#296` (root-vs-dependent rollup line + visual de-emphasis for
checks whose declared dependency is also failing) and `#297` (timeout debug strings must
name operation + target + budget, ideally measured-vs-budget) are both filed, scoped to
my design ([[copy_error_retry_guidance]] is the related copy-convention memory). I'm named
as consulted on #296's implementation; not self-dispatching, waiting for `implement issue`.

**The trap, from the 2026-08-08 lucos_time/IPv6-subnet incident:** the check that actually
fired first (`fetch-info`) is monitoring's own reachability probe — it carries no
`dependsOn` and structurally can't (it's what establishes whether the service is reachable
at all). The declared `dependsOn: lucos_time` lived on weightings' *other* check
(`time-api-reachable`), which never got to run because `fetch-info` failed first.

**How to apply:** any grouping/de-emphasis logic must key on `dependsOn` declared anywhere
in the affected *system's* `/_info`, not on the specific failing check's own `dependsOn`.
Keying on the failing check would silently fail to group the exact case that prompted the
issue. Verify this against the current `/_info` schema before implementing — confirm
`dependsOn` is still a system-level field, not per-check, and that `fetch-info` is still
the name of monitoring's own reachability probe.

Source: incident report `docs/incidents/2026-08-08-time-ipv6-subnet-collision.md` in
`lucas42/lucos`, Stage 3.
