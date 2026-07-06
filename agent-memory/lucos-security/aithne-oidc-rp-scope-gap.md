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

## Update 2026-07-03: gap being closed via lucas42/lucos_aithne#277

Reviewed and approved (design-sound) lucas42/lucos_aithne#277, which adds the
requested∩granted `effectiveScopes` claim (reusing [[lucos-aithne-security-architecture]]'s
`#258` intersection primitive) to the id_token and `/oauth2/userinfo`. Verified against
`main`: `MintIDToken` (`token/token.go`) has no scopes param yet and issuance stays
ungated (zero-grant principal still gets a valid id_token) — matches ADR-0001 §6.
Sequencing is correctly Blocked on #258 (confirmed unimplemented — `effectiveScopes`
doesn't exist in the codebase as of this review, #258 is Ready/unassigned-in-progress).

**Side observation surfaced during review (not filed as a separate issue — status quo,
not new):** `handleAuthorize` (`oidc.go`) accepts any `scope=` string from a registered
client with no per-client allowed-scopes list and no consent screen. Combined with #258,
any registered OIDC client can request arbitrary scope names and read back which ones the
principal holds — a scope-enumeration side channel. Not a new risk from #277: the RP
already gets the raw (unencrypted, signed-only) access_token JWT directly in the token
response and could decode it itself. Strictly less exposure than pre-#258 (full grant set
on every login), which lucas42 already accepted given first-party-only consumers. Revisit
only if a less-trusted/third-party OIDC client is ever registered.

## #258 shipped via PR #279 (reviewed + APPROVED 2026-07-06)

`handleAuthCodeGrant` now intersects `authCode.Scope` (requested) against
`GetActiveScopes` (granted) before minting the access token — reuses
`parseScopeParam`/`toSet` from the `client_credentials` downscoping path
(`machine_credentials.go`). Closes the over-scoping gap #258 described (access token
used to always carry the full grant-store set regardless of what was requested).

**Judgment call made on review, for reuse if this resurfaces:** `/oauth2/authorize`
requires `openid` in scope but no aithne scope, so `scope=openid` alone now yields an
access token with an **empty** scope set — differs from `client_credentials`'
omitted-scope→full-set fallback. Assessed this as **not a defect**: it's the safe
failure direction (ADR-0001 §6 — gate on scope, never bare session validity), and the
two grants have different minimum-scope contracts by construction (`authCode.Scope`
can never be truly empty since openid is mandatory, so client_credentials' fallback
branch has no equivalent trigger here). Net effect: OIDC path is *more* conservative,
not less. Worth an onboarding-docs note ("request every aithne scope you need —
`openid` alone gets nothing") but not a merge blocker. Don't re-litigate this as a
finding unless the actual behaviour changes.

#277 (the id_token/userinfo `effectiveScopes` claim) is still open/unimplemented as of
2026-07-06 — no conflict with #279 yet, but whoever implements #277 should be pointed
at the `requestedScopes`/`grantedSet` intersection already written in
`handleAuthCodeGrant` for consistency.
