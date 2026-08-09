---
name: configy-routed-domain-gap
description: configy has no model for a router-served domain with no system behind it; the router's hardcoded special cases are migration residue from lucos_router#11, not a designed extension point
metadata:
  type: reference
---

# configy's missing concept: a routed domain with no system behind it

## The gap

`lucos_configy` models **systems, volumes, hosts, components, scripts** (`api/src/data.rs`, routes in `api/src/routing.rs`) — that is the complete list. There is **no way to express "this domain, on this host, does this"** unless a deployed system with a repo sits behind it.

`systems.yaml` is a **repository registry**, not a domain registry: keys are repo ids, `lucos_repos`'s `in-lucos-configy` convention binds each repo to an entry, and `audit.go` builds its repo-type map from `/systems`. Inventing a pseudo-system for a bare domain creates a phantom repo in that map. So "it isn't a system" correctly rules out `systems.yaml` — but it does **not** justify hardcoding; it means the concept is missing.

## Facts that keep getting mis-stated

- **Non-`l42.eu` domains are NOT the boundary.** configy already routes `lukeblaney.co.uk`, `blog.lukeblaney.co.uk`, `semweb.lukeblaney.co.uk`, `app.tfluke.uk` through the ordinary path. The real boundary is *has a system/repo/backend* vs *doesn't*.
- **The router's hardcoded special cases are residue, not precedent.** `lucos_router` commit `2a53ca8` (closing lucas42/lucos_router#11, 2025-12-08) deleted `domain-sets/*` wholesale and carried **four** unexpressible lines across as `if [[ "$host_id" == … ]]` blocks in `fetch-domainsets.sh`: `nas.l42.eu`, `tfluke.uk`, `www.tfluke.uk`, `phys.l42.eu`. Down to three since (`phys` removed, `069f382`). lucas42's stated intent on #11 was to *stop* hardcoding domain lists in that repo.
- **`tfluke.uk`/`www.tfluke.uk` are not aliases of the `tfluke` system.** That system is `app.tfluke.uk` on port 3000; the apex/www pair proxy to `https://lucas42.github.io` — a different backend.
- **The gap has already leaked into a second repo.** `nas.l42.eu` is hardcoded both in the router's fetch script *and* as a literal line in `lucos_dns`'s `sync/templates/l42.eu.jinja` — a template whose purpose is rendering configy-derived records. Two hand-edits, one missing concept.

Only two behaviours exist in the wild: **proxy to an arbitrary URL** and **redirect to an arbitrary URL**. The domain-set line format `DOMAIN TARGET_URL` is already the first; the second needs one more column.

## DNS split (don't confuse it with the router split)

`lucos_dns` generates `l42.eu` and `s.l42.eu` zones from configy (`sync/config-sync.py` + Jinja). The three non-`l42.eu` zones (`lukeblaney.co.uk`, `rowanblaney.co.uk`, `tfluke.uk`) are **static hand-maintained files** in `bind/config/zones/`. Generating those would be a bigger job than it looks — the systems-zone renderer only emits A/AAAA/CNAME, and those zones carry MX, SPF, DKIM and verification TXT records.

## Router operational facts (verified 2026-08-09)

- `startup.sh` runs `update-domains.sh`, which re-fetches configy before certbot — **restarting the router genuinely forces a refresh** (also the README's documented way to force cert issuance; otherwise it waits for the 22:16 UTC cron).
- A `certbot certonly` failure short-circuits the `&&` chain and is swallowed by `|| true`, so a domain whose DNS doesn't point here yet is **skipped harmlessly** each run — no crash, no vhost written.
- Consequence for sequencing: **land code+config first, flip DNS second, restart immediately.** DNS-first maximises the dark window (a domain pointed at a router with no vhost hits the `000-error` catch-all over *both* schemes).
- Nothing currently prevents a system's domain colliding with a hardcoded one — two nginx `server_name` blocks for the same name. Putting both lists in configy makes that a build-time assertion in `api/tests/validation.rs`.

## Where this came up

lucas42/lucos_router#104 (2026-08-09) — self-hosting TLS-terminated redirects for 5 subdomains CNAMEd to `ghs.google.com`. lucas42 challenged the plan to hardcode them ("or we just vibing it big time?"). Assessment: recommended a new first-class configy resource, absorbing the 3 existing hardcodes, split into configy → router (Blocked on configy) → dns tickets. See [[feedback-check-originating-decision-before-forking]] — reading lucas42/lucos_router#11 was what settled it.

Scale at the time: 31 configy-derived routed domains (29 avalon, 2 xwing) vs 3 hardcoded; the ticket would have taken hardcodes to 8.
