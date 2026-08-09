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

## It is THREE separable limitations, not one concept

My first framing ("a domain with no system behind it") under-described it; so does "the backend isn't a local container port". Neither fits all the entries. The actual limitations:

1. **One hostname per system** — `domain` is `Option<String>` (`data.rs:46`), singular. Aliases are inexpressible *even for a local backend*.
2. **The backend is always a local container port** — configy stores `http_port`; `fetch-domainsets.sh` composes `http://172.17.0.1:$port`. No other target is expressible.
3. **Every domain must hang off a repo** — `systems.yaml` keys are repository ids.

The existing hardcodes hit *different combinations*, which is why no single characterisation fits: `tfluke.uk`/`www.tfluke.uk` → (1)+(2), **not** (3) (the `tfluke` repo exists and is registered). `nas.l42.eu` → (2)+(3). Redirect-only domains → (2)+(3).

`http_port` being absent is **not** one of the limitations — "domain with no port" is already schema-legal, live precedents `lucos_dns` and `lucos_dns_secondary`.

**Cost trap:** the repo-binding friction (dummy repo / `in-lucos-configy` exemption) is a cost of the **`systems.yaml`** option, *not* of a separate domain-keyed resource. That convention resolves types from `/systems`, `/components`, `/scripts` only and runs per GitHub repo, so a `domains.yaml` key is invisible to it. Don't let this inflate the price of the right option.

## DNS split (don't confuse it with the router split)

`lucos_dns` generates `l42.eu` and `s.l42.eu` zones from configy (`sync/config-sync.py` + Jinja). The three non-`l42.eu` zones (`lukeblaney.co.uk`, `rowanblaney.co.uk`, `tfluke.uk`) are **static hand-maintained files** in `bind/config/zones/`. Generating those would be a bigger job than it looks — the systems-zone renderer only emits A/AAAA/CNAME, and those zones carry MX, SPF, DKIM and verification TXT records.

## Router operational facts (verified 2026-08-09)

- `startup.sh` runs `update-domains.sh`, which re-fetches configy before certbot — **restarting the router genuinely forces a refresh** (also the README's documented way to force cert issuance; otherwise it waits for the 22:16 UTC cron).
- A `certbot certonly` failure short-circuits the `&&` chain and is swallowed by `|| true`, so a domain whose DNS doesn't point here yet is **skipped harmlessly** each run — no crash, no vhost written.
- Consequence for sequencing: **land code+config first, flip DNS second, restart immediately.** DNS-first maximises the dark window (a domain pointed at a router with no vhost hits the `000-error` catch-all over *both* schemes).
- Nothing currently prevents a system's domain colliding with a hardcoded one — two nginx `server_name` blocks for the same name. Putting both lists in configy makes that a build-time assertion in `api/tests/validation.rs`.

## Convergence asymmetry between the two configy consumers (reusable fact)

- `lucos_dns` sync cron: **every 15 minutes** (`sync/crontab`)
- `lucos_router` `update-domains.sh` cron: **once a day, 22:16 UTC** (`scripts/startup.sh`)

96×, pointing the wrong way. Once configy drives both, a new domain gets its CNAME published within 15 min and its cert up to 24h later. In the gap the domain resolves to the router with no vhost: port 80's `default_server` 301s everything to HTTPS (`conf/default.conf`), and HTTPS falls through to `templates/error.conf`'s `server_name _`, which serves the **host's own cert** → TLS name-mismatch. **Both schemes broken, not just HTTPS.**

Precision that stops this being overstated: for a *genuinely new* subdomain this is the accepted self-healing latency the router README documents. For *migrating a domain that already works*, it's a live regression. Only the second case needs a mitigation.

## Where this came up

lucas42/lucos_router#104 (2026-08-09) — self-hosting TLS-terminated redirects for 5 subdomains CNAMEd to `ghs.google.com`. lucas42 challenged the plan to hardcode them ("or we just vibing it big time?"). Assessment: recommended a new first-class configy resource, absorbing the 3 existing hardcodes, split into configy → router (Blocked on configy) → dns tickets. See [[feedback-check-originating-decision-before-forking]] — reading lucas42/lucos_router#11 was what settled it.

Scale at the time: 31 configy-derived routed domains (29 avalon, 2 xwing) vs 3 hardcoded; the ticket would have taken hardcodes to 8.

**DECIDED by lucas42, 2026-08-09** (lucas42/lucos_router#104): introduce the new configy concept; cover the 5 redirects **and** the 3 existing hardcodes; and it must power **both** the nginx logic **and** the `lucos_dns` entries. Structure of the type explicitly left open → ticket **lucas42/lucos_configy#267**, raised Needs Analysis owned by me. No ADR (decision taken on lucas42/lucos_router#11 + #104).

Decision 3 is the widening: `run_sync` only generates `l42.eu`/`s.l42.eu` today, so powering DNS means converting the static `lukeblaney.co.uk`/`rowanblaney.co.uk`/`tfluke.uk` zones to Jinja on the `l42.eu.jinja` pattern (static MX/SPF/DKIM/TXT preserved + generated CNAME loops).

## Sequencing reconciliation (the "DNS first or last?" trap)

Both "DNS must be updated before Let's Encrypt will mint" and "do DNS last" are true — different steps. DNS must precede the **certbot run**, not the **code deploy**. Correct order: (1) configy, (2) router code deploy — certbot fails harmlessly here, `|| true` swallows it and it retries, (3) DNS repoint ← *the README gotcha's step*, (4) restart router → cert mints. Say "DNS last **of the three code/config changes**" — unqualified "DNS last" reads as contradicting the cert constraint.
