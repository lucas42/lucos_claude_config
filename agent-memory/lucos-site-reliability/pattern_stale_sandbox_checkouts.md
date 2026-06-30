---
name: stale-sandbox-checkouts
description: ~/sandboxes/* checkouts can be MONTHS stale and contain undeployed repos — verify code against origin/main + live probes before raising migration/decom findings
metadata:
  type: feedback
---

`~/sandboxes/<repo>` checkouts are NOT current. They can lag `origin/main` by months and even contain repos that are no longer deployed (e.g. `lucos_comhra` — not in monitoring/configy/DNS).

**Why:** During the 2026-06-30 aithne post-migration SRE review, my LOCAL `lucos_photos/api/app/auth.py` still had `AUTH_DOMAIN="https://auth.l42.eu"` (the decommissioned service) with per-request remote introspection and no JWKS. I nearly raised SIX false "broken browser auth" incidents (photos, mmm, creds, loganne, notes, comhra). Live HTTP probes proved every deployed service redirects to `aithne.l42.eu/auth/login` — fully migrated — and `git show origin/main:.../auth.py` had a `_ResilientJWKSClient` (last-known-good). Local was ~2 months behind (last commit 2026-04-23).

**How to apply:** Before raising ANY code-derived finding (especially migration/decom "X still uses the old thing" claims):
1. `git -C ~/sandboxes/<repo> fetch origin` then read `git show origin/main:<path>` or `git grep <pat> origin/main` — never trust the working tree.
2. **Live-probe the runtime** — `curl -s -o /dev/null -w "%{http_code} %{redirect_url}" -H "Accept: text/html" <url>`. Runtime behaviour is authoritative over any source read. (This is the [[reference_loganne_read_self_verify]] / runtime-reachability discipline applied to code review.)
3. Cross-check undeployed-vs-deployed via monitoring/configy/DNS before treating a repo as live.

The hedging rule bit me here: I reasoned from stale code as if it were live state. Evidence (live probe) > inference (local source).
