---
name: router-dual-cert-renewal-paths
description: lucos_router has TWO cert-renewal paths; decommissioned domains leave orphaned certbot renewal configs the stock cron keeps retrying
metadata:
  type: project
---

`lucos_router` renews TLS certs via **two independent paths**, and they don't know about each other:

1. **configy-driven** — `update-domains.sh` (nightly cron `16 22 * * *`) reads the domain set from configy (`fetch-domainsets.sh` → `/etc/nginx/domain-sets/$HOSTDOMAIN`) and runs `certbot certonly -d <domain>` per domain in the set. Remove a domain from configy → this path stops touching it.
2. **stock Debian cron** — `python3-certbot-nginx` ships `/etc/cron.d/certbot` (`0 */12 * * *` + random sleep), which `service cron start` activates. It runs `certbot renew`, iterating `/etc/letsencrypt/renewal/*.conf` — **completely configy-unaware**. Renews anything with a renewal config, regardless of the domain set.

**The trap:** the #58 stale-config-removal loop in `update-domains.sh` (lines ~84-97) removes orphaned *nginx* config blocks for decommissioned domains, but does NOT remove orphaned *certbot renewal configs* (`/etc/letsencrypt/renewal/<domain>.conf`) or live certs. So path 2 keeps attempting renewal of dead domains **forever**, failing twice-daily with NXDOMAIN, logging ERROR lines to the shared `/var/log/letsencrypt/letsencrypt.log`.

**Why this bit me (2026-06-03, router#90):** I raised a ticket saying "certbot runs nightly and will attempt to renew" — implying the configy path. lucas42 correctly doubted it ("if comhra's out of configy, what's driving renewal?"). The real driver was path 2, which I'd overlooked. I also wrongly recommended removing an nginx config block that the #58 loop had already auto-removed (pure vibes).

**Diagnosis recipe for "stale cert keeps trying to renew":**
- `docker exec lucos_router ls /etc/letsencrypt/renewal/` — is the orphan's `.conf` still there?
- `docker exec lucos_router grep -rl <domain> /etc/nginx/domain-sets/` — confirm it's NOT in the configy-derived set
- `docker exec lucos_router grep -i <domain> /var/log/letsencrypt/letsencrypt.log | grep -iE 'fail|error|nxdomain'` — confirm live failures
- Cert lives on whichever host served the domain (per-host; comhra was avalon-only, xwing clean).

**Fix:** `certbot delete --cert-name <domain>` inside the container (removes live + archive + renewal conf, stops path 2). Failed renewal of one cert does NOT block others — `certbot renew` processes each independently, so impact is log noise only (P3). Root-cause fix would extend the #58 loop to also drop orphaned renewal configs, but `certbot delete` is destructive vs Let's Encrypt rate limits — sharp edge, developer task not ops one-liner.

**RESOLVED 2026-06-03 via PR #91** (1.0.20). update-domains.sh now iterates `/etc/letsencrypt/renewal/*.conf` after the nginx-config cleanup and `certbot delete`s any cert whose domain isn't in the active HTTP domain set (keeping `$HOSTDOMAIN`). Verified on avalon: removed comhra **and dns.l42.eu**, kept all 30 domain-set certs + HOSTDOMAIN. **Nuance — the criterion is "not in the HTTP domain set", which is broader than "decommissioned":** it also reaps router certs for live configy systems with `http_port = null` (e.g. `lucos_dns`/dns.l42.eu — DNS on :53, no HTTP). Harmless + correct (router only holds certs for domains it serves + HOSTDOMAIN; self-healing if http_port returns — configy `certbot certonly` re-issues), but be aware: a cert vanishing from the router store doesn't mean the domain is dead, just that it's not HTTP-served. dns.l42.eu:443 still serves the HOSTDOMAIN (avalon.s.l42.eu) cert via the default server block, as it always did.
