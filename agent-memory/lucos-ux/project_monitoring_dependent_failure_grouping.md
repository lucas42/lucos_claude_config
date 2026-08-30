---
name: monitoring-dependent-failure-grouping
description: lucos_monitoring#296 (dependent-failure grouping) — SHIPPED via PR #306; the fetch-info dependsOn trap and how it was solved
metadata:
  type: project
---

`lucas42/lucos_monitoring#296` (root-vs-dependent rollup line + visual de-emphasis for a
failing system whose failure is explained by another currently-failing system) is
**SHIPPED**: PR https://github.com/lucas42/lucos_monitoring/pull/306, approved by
lucos-code-reviewer 2026-08-30, awaiting lucas42 (supervised repo). `#297` (timeout debug
strings) is separate, still open, also scoped to my design
([[copy_error_retry_guidance]]).

**The trap, from the 2026-08-08 lucos_time/IPv6-subnet incident:** the check that actually
fired first (`fetch-info`) is monitoring's own reachability probe — it carries no
`dependsOn` pointing at the true root and structurally can't for that purpose (ADR-0004
stamps it with `[lucos_router, lucos_dns]` instead, for a different reason). The declared
`dependsOn: lucos_time` lived on weightings' *other* check (`time-api-reachable`), which
never got to run because `fetch-info` failed first but whose *cached* value (from its last
successful poll) is still present in the merged checks map.

**How it was solved:** classification scans **all** of a system's checks (the merged
normalised-cache map already available server-side) for any `dependsOn`, not just the
currently-failing check's — `systemDependsOn/1` in `view.erl`. A system is `dependent` if
any declared dependency is itself currently `failing` (system-level status, single-hop,
no chain-following — matches ADR-0002/0004). The one new backend surface is exposing each
check's already-computed `normalise_depends_on/1` result in `buildCheckOutput/2`, which
had computed but never surfaced it.

**A second bug the eunit tests didn't catch, only a screenshot did:** the dashboard's
existing sort is `{status_priority, Name, Host}` — pure alphabetical within a status group.
With that sort, a dependent (e.g. `lucos_media_weightings`) rendered *above* its own root
cause (`lucos_time`) whenever it sorted first alphabetically, undercutting the whole "read
why at a glance" goal even though the rollup line and classification were both correct.
Fixed by keying the sort on `{RootSystemId, IsDependent}` instead of the system's own name
— see [[feedback_screenshot_catches_ordering_bugs_unit_tests_miss]] for the general lesson.

Source: incident report `docs/incidents/2026-08-08-time-ipv6-subnet-collision.md` in
`lucas42/lucos`, Stage 3.
