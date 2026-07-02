---
name: aithne-oidc-rp-scope-gap
description: aithne's OIDC id_token/userinfo don't carry the scopes claim, so generic OIDC RPs (oauth2-proxy etc.) can't gate on aithne scopes out of the box
metadata:
  type: project
---

# aithne OIDC relying-party scope gap

Verified 2026-07-02 by reading `lucos_aithne`'s `oidc.go` and `token/token.go`, during the
owntracks/lucos_locations security steer (lucas42/lucos_locations#90).

**The gap:** aithne is a full OpenID Provider (ADR-0001 §1) for services that *can't* do
local JWT verification (e.g. static SPAs fronted by a generic OIDC RP like oauth2-proxy,
not a Go/Node/Python backend). But the OIDC surface those RPs actually consume is thin:

- `MintIDToken` puts only `iss, sub, aud, exp, iat, jti, principal_class, nonce` in the
  id_token. No `scopes`, no `email`, no `name`.
- `/oauth2/userinfo` (`handleUserinfo`) returns `sub`, `principal_class`, and (humans only,
  best-effort) `name` from lucos_contacts. Also no `scopes`.
- The `scopes` claim only ever appears on the **access_token** (aud=`l42.eu`), which is
  what services doing [[lucos-aithne-security-architecture]]-style local JWKS verification
  consume — not what a generic OIDC RP authenticates against.

**Consequence:** any service that has to front itself with a generic OIDC RP (oauth2-proxy
or similar) because it has no backend of its own to run local JWT verification **cannot**
gate access on an aithne scope today. It can only gate on `sub` (e.g. an allow-list via
`--oidc-email-claim=sub` + `--authenticated-emails-file`, oauth2-proxy flag names not
personally verified) or on claims the id_token/userinfo actually carry.

**If a future service wants scope-based authZ via a generic OIDC RP**, that requires an
aithne-side change first — expose `scopes` (or a derived claim) via `/oauth2/userinfo`
and/or the id_token — this is a prerequisite issue against `lucos_aithne`, not a same-PR
config choice in the consumer.

**Where this will recur:** any owntracks-style retrofit — a static SPA or third-party
frontend with no backend, put behind aithne via a sidecar OIDC RP rather than the
Go/Node/Python local-verification pattern most consumers use. Check this gap early in any
such design.
