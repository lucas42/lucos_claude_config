---
name: reference-loganne-access
description: How to query loganne as an agent — bearer token, key location, client-side filtering
metadata:
  type: reference
---

## Loganne read access for agents

**Auth:** `Authorization: Bearer $KEY_LUCOS_LOGANNE` — the key is in `~/sandboxes/lucos_agent/.env`.

**Endpoint:** `GET https://loganne.l42.eu/events`

**No query params filter server-side** (until lucas42/lucos_loganne#522 ships). `?source=`, `?type=`, `?limit=`, `?count=` are silently ignored — the full feed is always returned (newest-first). `?since=` and `?level=` do work. Filter everything else client-side until #522 lands.

**Working pattern:**
```bash
source ~/sandboxes/lucos_agent/.env
curl -s -H "Authorization: Bearer $KEY_LUCOS_LOGANNE" https://loganne.l42.eu/events \
  | python3 -c "
import sys, json
events = json.load(sys.stdin)
for e in [e for e in events if e.get('source')=='lucos_creds'][:10]:
    print(e.get('date',''), e.get('humanReadable',''))
"
```

**Useful fields:** `source`, `type`, `date`, `humanReadable`

**Event types:** `credentialUpdated` (not `linkedCredentialUpdated`) for lucos_creds events.

**Auth model:** shared read key, not per-client CLIENT_KEYS. Fine for read-only audit logs.

**Note:** `KEY_LUCOS_LOGANNE` is a shared read key — fine for read-only audit logs, no per-agent rotation needed.
