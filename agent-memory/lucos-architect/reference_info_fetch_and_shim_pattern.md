---
name: info-fetch-and-shim-pattern
description: How /_info is fetched (public domain, single-backend router) and the reverse-proxy shim pattern for adopted third-party apps that can't self-serve /_info
metadata:
  type: reference
---

Both `/_info` consumers fetch over the **public HTTPS domain**, not internal host:port:
- `lucos_monitoring` `src/fetcher_info.erl`: `"https://" ++ Domain ++ "/_info"` (Domain = configy `domain`). CI is now sourced from configy, NOT `/_info` (the `ci` field is ignored).
- `lucos_root` `src/main.go`: `scheme://entry.Domain + "/_info"`; reads only `title/icon/network_only/start_url/show_on_homepage` and builds absolute `IconURL`/`PageURL` = `https://domain + path` (so `icon` must be a real path that 200s on the domain).

`lucos_root` and `lucos_monitoring` both **auto-generate** their system list from `configy.l42.eu/systems/http` at image-build time. So a service with an `http_port` in configy `systems.yaml` is monitored automatically on the next monitoring rebuild — and if it 404s `/_info` it shows **red**. "Do nothing" is therefore not a stable resting state for an adopted app.

`lucos_router` maps each domain to a **single backend**: `templates/https.conf` is one `location / { proxy_pass {{backend}}; }` (+ a websocket location to the same backend). **No per-path backend split** — so `{domain}/_info` is served by whatever the single domain backend is. Splitting `/_info` to a separate backend would be an estate-wide router-template change.

**Adopted-third-party-app `/_info` shim pattern** (worlds#6, BookStack, 2026-07-09): app can't serve lucos `/_info`. Because both consumers hit `https://{domain}/_info` and the router is single-backend, the `/_info` must be served *inside* the deployment → put a small **reverse-proxy shim** (~60-line Go, `httputil.ReverseProxy`) as the domain's backend: serves live `/_info`, proxies everything else to the app (which drops its published port, stays internal). Health check must be a **request-time probe of the app's real health endpoint** (BookStack `/status`: `{database,cache,session}`, 200 all-true/500 any-false, public) — NOT static, or it shows green while a dependency is down (violates "Docker healthy ≠ reachability"). Preserve `Host` + `X-Forwarded-Proto: https` through the shim so the app's OIDC absolute-URL/redirect logic stays intact. Rejected alt: injecting `location=/_info` into the app's internal (LSIO) nginx — static payload can't reflect dep health + deepens fragile upstream coupling. See [[reference_docker_healthy_not_reachability]].
