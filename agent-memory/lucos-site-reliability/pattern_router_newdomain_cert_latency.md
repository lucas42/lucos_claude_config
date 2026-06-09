---
name: pattern-router-newdomain-cert-latency
description: New service's tls-certificate/fetch-info failing on the board = router hasn't issued its cert yet; pull-only, daily 22:16 UTC cron or restart
metadata:
  type: project
---

A newly-registered configy service showing `tls-certificate` + `fetch-info` failing (cert received = host default e.g. `avalon.s.l42.eu`, `hostname_check_failed`/`bad_certificate`) is **NOT an incident** — the router just hasn't issued the cert yet.

**Why:** lucos_router domain discovery is **pull-only, no push trigger from configy.** `scripts/fetch-domainsets.sh` curls `configy.l42.eu/hosts/http` + `/systems/host/{id}` to build the domain set; `scripts/update-domains.sh` runs `certbot certonly` per domain + nginx reload. `scripts/startup.sh` runs `update-domains.sh` only **on container startup** and via a **daily cron at 22:16 UTC** (`16 22 * * *`). So a new domain waits up to ~24h for its cert.

**How to apply:**
- To force issuance immediately: restart `lucos_router` on the service's host (runs `update-domains.sh` on startup). Otherwise wait for the 22:16 UTC daily cron.
- Verify the real serving cert with `echo | openssl s_client -connect <domain>:443 -servername <domain> | openssl x509 -noout -subject -dates`. Note Let's Encrypt **backdates `notBefore` by ~1h**, so a cert with notBefore 21:17 was actually issued ~22:17 (matches the 22:16 cron) — don't misread the backdated time as the issuance time.
- Board self-heals at the next cron run; recovery timestamp landing near 22:16 UTC = the daily cron did it, not a restart.

First hit 2026-06-09 standing up `lucos_aithne` (creds 16:53 → alerts 17:51 → cron-issued + recovered 22:16:54). Documentation gap tracked in lucas42/lucos_router#95 (P3 — decided document-don't-automate; a configy→router webhook isn't justified for a few-times-a-year internal-only self-healing event).
