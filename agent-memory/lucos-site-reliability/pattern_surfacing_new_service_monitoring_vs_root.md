---
name: pattern-surfacing-new-service-monitoring-vs-root
description: When a new service goes live, monitoring needs a REBUILD to pick it up (build-time baked system list) but lucos_root homepage picks it up at RUNTIME (no rebuild) — different mechanisms, don't assume "just a rebuild" for both
metadata:
  type: reference
---

Both lucos_monitoring and lucos_root build their system list from configy `/systems/http` (systems with an `http_port`), but at **different times**, so onboarding a new service differs:

- **lucos_monitoring — REBUILD required.** The list is baked into the image at **build time**: the Dockerfile `curl`s `configy.l42.eu/systems/http` → `config/info-systems-list.json`, and `fetcher_info:start/1` reads that file **once at startup**. Runtime only re-polls each system's `/_info` every 60s (`tryRunChecks` loop) — it never re-reads the *list*. So a container restart won't add a new system; only a fresh CircleCI build+deploy regenerates the baked list. Trigger it yourself: `POST /api/v2/project/gh/lucas42/lucos_monitoring/pipeline {"branch":"main"}` (my PAT). After deploy, expect a brief post-restart warm-up (`unknown: N`) that clears within ~2 min as per-system polls run — [[pattern_deploy_window_boundary_crossprobe_flap]] / production-change-verification: wait and confirm it settles, don't report it as a regression.
- **lucos_root homepage — NO rebuild.** `lucos_root/src/main.go` `ServiceListPanel` fetches configy `/systems/http` at **runtime** (5-min cache, `configyCacheTTL`) and polls each `/_info` every 60s (`refreshInterval`), reading `show_on_homepage`. A new service with `http_port` in configy + a `/_info` serving `show_on_homepage:true` appears on l42.eu within ~5-6 min automatically.

**Precondition for both:** the service must have `http_port` in configy `systems.yaml` AND serve a valid lucos `/_info`. If `/_info` 404s but `http_port` is set, monitoring's next rebuild adds it and it shows **red** (fetch-info fail) — see [[pattern_info_endpoint_boundary]] and the worlds case below.

**Worked example — lucos_worlds (BookStack), 2026-07-09.** BookStack is third-party and has no native `/_info`; worlds#47 added an `/_info` shim mapping BookStack's native `/status` (`{database,cache,session}`) → a `bookstack` check. Once `worlds.l42.eu/_info` went live: root surfaced worlds on its own (runtime); monitoring needed pipeline #656 to rebuild. Result: worlds healthy on dashboard with checks tls-certificate / fetch-info / circleci / bookstack. Note worlds `/_info` also sets `network_only:true`.
