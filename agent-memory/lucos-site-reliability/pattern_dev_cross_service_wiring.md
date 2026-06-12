---
name: pattern-dev-cross-service-wiring
description: How lucos services reach each other in the dev environment (host.docker.internal, not bridge IPs) and the stale-.env-vs-creds 403 trap
metadata:
  type: reference
---

Wiring two lucos services together in **local dev** (proven aithne→contacts, 2026-06-12):

**Host/network layer — use `host.docker.internal`, never a raw bridge IP.**
- Cross-service `*_ORIGIN` in dev should be `http://host.docker.internal:<hostPort>`, NOT `http://172.17.0.1:<port>`. `172.17.0.1` is just the default docker0 gateway — shifts with bridge/subnet reconfig, and (critically) Django services list `host.docker.internal` in `ALLOWED_HOSTS` but NOT the bridge IP, so the IP gets a **400 DisallowedHost** (Django checks the request `Host:` header = hostname part of the origin URL against `ALLOWED_HOSTS`).
- On **Linux Docker Engine** the name doesn't resolve without `extra_hosts: ["host.docker.internal:host-gateway"]` in the caller's compose service (Docker Desktop has it built in). `host-gateway` adds an /etc/hosts alias to the host gateway — a name, not a new route; inert in prod (prod origins point at the public router e.g. `https://contacts.l42.eu`).
- Diagnose by curling the target with different `Host:` headers: only members of its `ALLOWED_HOSTS` return 200.

**Auth layer — the cred is a lucos_creds LINKED credential; don't hand-edit CLIENT_KEYS.**
- aithne→contacts auth = `ssh -p 2202 creds.l42.eu "lucos_aithne/development => lucos_contacts/development"` (README §"linked credentials"). Auto-populates `KEY_LUCOS_CONTACTS` on the client side AND appends `client:env=key` to `CLIENT_KEYS` on the server side. One source of truth; never edit either side manually.
- contacts' `getUserByKey` (lucosauth/envvars.py) looks up the raw bearer key in `CLIENT_KEYS`; unknown key → **403** (distinct from the 400 host-layer failure, which fires first in middleware before auth).

**The trap that cost time:** a **stale local `.env` vs creds** looks exactly like a missing/wrong key. The running contacts container had been started from a local `.env` that predated the linked cred, so it 403'd — but creds already had the correct pairing. Fix is `scp -P 2202 "creds.l42.eu:<system>/development/.env" .` + restart the container, NOT a creds write. **Always diff the local `.env` against a fresh creds fetch before concluding a credential is wrong.**

Simple creds write: `ssh -p 2202 creds.l42.eu "<system>/<env>/<KEY>=<value>"` (value must contain no `=`; splits on first `=`). Re-fetch to verify.
