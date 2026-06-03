---
name: dependson-two-read-sites
description: lucos_monitoring dependsOn has TWO read sites — the suppress filter AND the unsuppress cascade; trace both before reasoning about a dependsOn change
metadata:
  type: project
---

In `lucos_monitoring` (`src/monitoring_state_server.erl`), `dependsOn` is read in **two** places (per ADR-0002). When reasoning about any dependsOn change, trace BOTH — not just the obvious one:

1. **Suppress filter — `is_dependency_suppressed/3`** (called from `state_change/3` and `aggregateCheckStatuses/3`). Per-check: if a failing check's dependsOn target is in an active suppression window, the failure is suppressed. Check-shape-agnostic (reads `maps:get(<<"dependsOn">>, Check)` off any check map, synthetic or service-declared). This is the one everyone thinks of.

2. **Unsuppress cascade — `find_dependent_systems/2`** (≈ lines 591-605) feeding the cascade at lines ~258-273. When a system's suppression window *closes* (deploy ends / `/suppress/clear`), monitoring enumerates **every system whose checks name the unsuppressing system in dependsOn** and sweeps them all into `#pending_verification{}` for one poll cycle (defer alert decision until fresh post-deploy data). Single-hop only.

**Why this matters:** a change that makes a dependsOn *universal* (e.g. stamping `dependsOn:[lucos_router, lucos_dns]` onto the synthetic fetch-info/tls-certificate probes that EVERY system gets — see [[pattern_dependson_deploy_window_only]] and lucos_monitoring#272) is cheap on read site 1 but on read site 2 fans pending_verification across the **entire estate** on every router/dns deploy. Mostly benign (stale reachability → defer one poll, healthy clears next poll), but it briefly defers alerting on router-*unrelated* failures estate-wide, and widens the cascade far beyond ADR-0002's original case (5 webhook targets → 1 consumer).

**Bit me 2026-06-03** on #272: I wrote "no change to the suppression engine" having traced only read site 1. Architect caught the cascade in review (→ ADR-0004 / PR #273). Lesson: dependsOn isn't just "suppress when dep is deploying" — it also drives a post-deploy verification cascade. Grep `normalise_depends_on` to find ALL call sites before claiming a dependsOn change's blast radius.
