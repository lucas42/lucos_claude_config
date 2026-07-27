---
name: loganne-read-self-verify
description: How to query loganne to self-verify credential/deploy events — bearer auth, client-side filtering, event types
metadata:
  type: reference
---

To independently verify that credential rotations or deploys actually landed (instead of relying on human confirmation), query loganne directly:

```bash
source ~/sandboxes/lucos_agent/.env
curl -s -H "Authorization: Bearer $KEY_LUCOS_LOGANNE" https://loganne.l42.eu/events | python3 -c "..."
```

- **Auth:** bearer `KEY_LUCOS_LOGANNE` (in `~/sandboxes/lucos_agent/.env`). The browser-auth redirect is only the *no-token* fallback — supply the header and you get HTTP 200 + JSON.
- **Server-side filters — re-measured 2026-07-27.** `?since=<YYYY-MM-DD>`, `?level=` and `?type=` work (`type` shipped via [lucos_loganne#522](https://github.com/lucas42/lucos_loganne/issues/522), **closed 2026-06-10**). **`?limit=` is still silently IGNORED** — `limit=50`, `limit=2000` and `limit=3000` all return the identical fixed ~470-event (~7-day) page; so do `offset`/`page`/`before`/`from`/`start`/`days`/`system`. This is the dangerous one: a bare `?limit=2000` *looks* like a 30-day query and returns 7 days.
- **`since` is event-bounded, not date-bounded.** It caps at ~2278 events — `since=2026-05-01` still only reaches back to ~2026-06-30 (~27d). **Always print the actual min/max `date` of what you fetched and scope claims to that range**, never to the range you requested. `agents/sre-ops-checks.md` Checks 2+3 were fixed on 2026-07-27 to use `since=` and print the fetched range; before that they had been silently reporting "30-day" results from a 7-day window.
- **Credential events:** `type=credentialUpdated`, `source=lucos_creds`, humanReadable e.g. *"Credential KEY_LUCOS_EOLAS updated in lucos_arachne (production) with scope read"*. NOTE: `updateLinkedCredential` ROTATES the key on every update (storage.go ~L365, unconditional `generateNewEncryptedValue`) — so any client still running its old key 403s until it redeploys.
- **Deploy events:** `type=deploySystem`, source `lucos_deploy_orb`, humanReadable *"Deployed lucos_X v1.0.N to <host>"*. Use to confirm a deploy REALLY happened vs just CI-green.

Authoritative auth verification for an eolas-style scope rollout: grep eolas's own logs (`lucos_eolas_web` / `lucos_eolas_app` on avalon — NOT `lucos_eolas`) for `403|forbidden|scope|denied` AND positively confirm clients' real authed calls returned 200. Verified 2026-06-07 eolas scope-enforcement rollout (PR #298): mma's `POST /metadata/names` 200 confirmed the write path that has no continuous monitoring check.
