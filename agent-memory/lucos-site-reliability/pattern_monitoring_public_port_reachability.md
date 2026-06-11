---
name: monitoring-public-port-reachability
description: monitoring now probes configy public_ports for TCP reachability (port-N-reachable checks); plus the /systems/http vs /systems filtering gotcha
metadata:
  type: reference
---

monitoring has `port-<N>-reachable` checks (source `ports`, module `src/fetcher_ports.erl`, shipped via lucos_monitoring#281 / PR #282, 2026-06-12). A red `port-25-reachable` on `lucos_mail` = SMTP port down (the gap that made the 2026-06-11 Dovecot crash-loop invisible). Five targets: mail 25, creds 2202, locations 8883, dns 53, dns_secondary 53.

Mechanics worth remembering:
- **`/systems/http` FILTERS to systems with an `http_port`.** So `lucos_dns`, `lucos_dns_secondary`, `lucos_router` are ABSENT from it (no http_port). The FULL `configy.l42.eu/systems` endpoint emits `public_ports` for ALL systems. fetcher_info builds `info-systems-list.json` from `/systems/http` (so fetch-info/tls only cover http systems — see [[pattern_monitoring_coverage_http_vs_scheduled]]); fetcher_ports builds a SEPARATE `info-ports-list.json` from the full `/systems`. If you ever need a per-system attribute for a non-http box, `/systems/http` will silently omit it — use `/systems`.
- **`public_ports` is the same list that drives lucos_firewall's inbound allow-list** → "declared public" ⟺ "firewall-open" ⟺ "monitored" by construction.
- Probe = bare `gen_tcp:connect(domain, port, 1s)`, no TLS/payload. Connection errors (econnrefused/timeout/nxdomain/etc) → `unknown`, so a sustained-down port escalates via the UnknownsGate (5 polls) → FailsGate, ~6 min to alert; single restart blip absorbed. Only unexpected errors → false.
- **It's a LIVENESS FLOOR, not functional health.** Green = port accepts a TCP connection. For DNS specifically: green = TCP-fallback listener up, NOT that resolution works (primary path is UDP:53, not probed).
- Router excluded generically by absence of a `domain` (no connect target), not a named special-case — robust to future domain-less systems.
- dependsOn is `[lucos_dns]` ONLY (not router): a raw TCP probe bypasses nginx, so a router-deploy dependency would suppress the very outage it catches. (failThreshold:2 + this dependsOn via local `make_port_probe_check/1`, deliberately NOT fetcher_info's `make_direct_probe_check` which stamps [router,dns].)

State-server detail: checks merge per-`Source` (`source_checks_map`), so the `ports` source coexists with `info`/`circleci`/`scheduled_jobs` rather than clobbering. A new source for an already-seen system is safe.
