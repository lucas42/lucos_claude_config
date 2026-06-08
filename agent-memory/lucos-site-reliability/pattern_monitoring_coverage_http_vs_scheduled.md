---
name: pattern-monitoring-coverage-http-vs-scheduled
description: How lucos_monitoring decides what gets a fetch-info check vs scheduled-jobs — a system with a domain but no http_port has NO fetch-info, only schedule_tracker + circleci
metadata:
  type: pattern
---

# Monitoring coverage: fetch-info requires http_port; non-HTTP boxes are covered via schedule_tracker

Verified against lucos_monitoring + lucos_schedule_tracker source, 2026-06-05 (DNS-secondary SOA-monitoring design, lucas42/lucos#217).

## The build-time filter (the surprising bit)

`info-systems-list.json` is generated at **Docker build time** from `https://configy.l42.eu/systems/http` (lucos_monitoring `Dockerfile` L17) — the **HTTP-systems** endpoint. Only systems with an `http_port` in configy appear.

- `fetcher_info` reads that file and fetches `/_info` over HTTPS for each entry → produces the `fetch-info` + `tls-certificate` checks.
- A system with a `domain` but **no `http_port`** (e.g. `lucos_dns` = BIND on :53, no HTTP server) is **excluded at build time** → it has **NO fetch-info and NO tls-certificate check at all**.
- Confirmed live: `monitoring.l42.eu/api/status` shows `lucos_dns` with checks `[config-sync, circleci]` only.
- Gotcha: `fetcher_info.erl` L14-15 only filters on *empty domain* — that is NOT the real exclusion. The real exclusion is the upstream `/systems/http` build query. Don't conclude "has domain ⇒ gets fetch-info."

**Implication:** never assume a non-HTTP box's liveness is covered by fetch-info. It isn't.

## How non-HTTP boxes ARE monitored: schedule_tracker scheduled jobs

`fetcher_scheduled_jobs.erl` polls `schedule_tracker /jobs` every 60s and attributes each job to a system:

- Attribution is by the job's own `system` field (`parseJobEntry` L76); check-key = `job_name` (or `scheduled-job` if unnamed).
- It surfaces a job **even if that system isn't in `/systems/http`**, via the fallback `maps:get(SystemStr, SystemsMap, {SystemStr, system})` (L51) — Host defaults to the id string. This is how `lucos_dns`'s `config-sync` check appears despite lucos_dns not being an HTTP system.
- The check map (`ok`/`techDetail`/`debug`) comes verbatim from schedule_tracker — so the `ok` evaluation lives in schedule_tracker, NOT in lucos_monitoring (respects the lucos_monitoring#189 "service-specific checks don't live in monitoring" boundary).

## schedule_tracker check semantics (lucos_schedule_tracker/src/database.rb `derive_job_entry`)

A job's check fails (`ok:false`) on EITHER:

1. **Overdue (liveness):** `age >= time_threshold`, where `time_threshold = frequency × 3` for sub-4-day frequencies (`calculate_time_threshold`). If the cron runs **on the box** and the box dies → no push → overdue → alert after ~3× cadence. So overdue covers "box down" — provided the job runs on the box being monitored.
2. **Consecutive errors (staleness):** `error_count >= error_threshold`, where `error_threshold` is frequency-derived: **5 / 4 / 3 / 2** for freq `<10m / <30m / <90m / ≥90m` (`calculate_error_threshold`).

So schedule_tracker is a **single mechanism for both liveness and staleness**. Key constraint: the **failThreshold/grace is NOT a free per-job knob** — it's derived from cadence. Tune grace via frequency, or bake extra grace into the job itself (e.g. re-check before pushing an error). A ≥90-min cadence collapses grace to 2.

Scheduled-job checks get **no** `dependsOn` deploy-window suppression (that's stamped only on fetch-info via `make_direct_probe_check` in fetcher_info) — a deploy may briefly error; the frequency grace absorbs it.

## Concrete instance: salvare is NOT monitored over IPv6 (and that's fine) — 2026-06-08

Architect flagged that `lucos_monitoring`+`lucos_time` have `EnableIPv6=false` on their docker networks (confirmed live; avalon `daemon.json` has no `ip6tables`) → monitoring can't originate IPv6, so salvare's "IPv6-only services" might be silently unreachable. **Verified FALSE as a gap:** all 3 salvare-hosted systems (`lucos_docker_health`, `lucos_firewall`, `lucos_media_linuxplayer`) have **no http_port/domain** → zero fetch-info probes to salvare; salvare has no `serves_http`. salvare is monitored entirely via OUTBOUND push: docker_health's `salvare-v4` schedule_tracker check (salvare→avalon, IPv4, healthy=actively reporting) + per-system `circleci` checks. Monitoring never makes an inbound IPv6 probe to salvare, so its lack of IPv6 egress is irrelevant. Green board = accurate. **General principle to remember:** monitoring's no-IPv6-egress only matters for a monitored domain that resolves **AAAA-only** AND gets a fetch-info probe — that's the only shape where "can't reach over IPv6" is a real gap. salvare isn't that shape. **Estate-wide AAAA-only sweep run 2026-06-08 to close the general concern: pulled monitored domains from configy `/systems/http`, dig A+AAAA each → 30/30 have an A record, 2 dual-stack, 0 AAAA-only, 0 no-address. No actual IPv6 gap anywhere.** Re-runnable anytime; only re-opens if someone publishes an AAAA-only monitored service.

## Practical: monitoring a non-HTTP box without standing up an HTTP server

Don't build an `/_info` HTTP server just to surface one check on a non-HTTP box (extra TLS/router/attack surface — bad on e.g. an authoritative nameserver). Instead: a cron on the box pushes to schedule_tracker. A plain `curl` POST to `/v2/report-status` (fields: system, frequency, status, job_name, message) is enough — no need for the python client. lucos_dns's `config-sync` push is the working reference.
