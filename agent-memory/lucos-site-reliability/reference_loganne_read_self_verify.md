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
- **Filtering is client-side only.** `GET /events` IGNORES `?source=`, `?type=`, `?limit=`, `?count=` — they all return the full feed (~1500 events). Only `?since=<date>` and `?level=` actually work server-side (`src/routes/events.js`). Filter in-client until [lucos_loganne#522](https://github.com/lucas42/lucos_loganne/issues/522) ships (filed 2026-06-07, ~4-line fix to add source/type filters).
- **Credential events:** `type=credentialUpdated`, `source=lucos_creds`, humanReadable e.g. *"Credential KEY_LUCOS_EOLAS updated in lucos_arachne (production) with scope read"*. NOTE: `updateLinkedCredential` ROTATES the key on every update (storage.go ~L365, unconditional `generateNewEncryptedValue`) — so any client still running its old key 403s until it redeploys.
- **Deploy events:** `type=deploySystem`, source `lucos_deploy_orb`, humanReadable *"Deployed lucos_X v1.0.N to <host>"*. Use to confirm a deploy REALLY happened vs just CI-green.

Authoritative auth verification for an eolas-style scope rollout: grep eolas's own logs (`lucos_eolas_web` / `lucos_eolas_app` on avalon — NOT `lucos_eolas`) for `403|forbidden|scope|denied` AND positively confirm clients' real authed calls returned 200. Verified 2026-06-07 eolas scope-enforcement rollout (PR #298): mma's `POST /metadata/names` 200 confirmed the write path that has no continuous monitoring check.
