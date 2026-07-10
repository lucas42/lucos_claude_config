---
name: reference-oauth2proxy-aithne-pattern
description: oauth2-proxy-fronting-aithne pattern (lucos_locations#97) — groups-claim remapping, scope-request gotcha, ES256 pinning gotcha
metadata:
  type: reference
---

# oauth2-proxy fronting an aithne-gated service (lucos_locations#97, 2026-07-10)

First server-to-server aithne OIDC integration in the estate (oauth2-proxy sidecar +
nginx `auth_request`, gating human map-UI paths on `locations:read`; device/MQTT paths
stay on existing credential auth since a phone can't do interactive OIDC). Reviewed and
approved (COMMENT, non-blocking — lucos_locations isn't always-review, code-reviewer did
the source-level verification and held the formal sign-off). Worth knowing the pattern
for the next service that fronts itself with oauth2-proxy against aithne, since these
gotchas will recur.

## `ALLOWED_GROUPS` is NOT decorative here — it's remapped to real scopes

`OAUTH2_PROXY_OIDC_GROUPS_CLAIM=scopes` + `OAUTH2_PROXY_ALLOWED_GROUPS=locations:read`
retargets oauth2-proxy's IdP-group-membership machinery at aithne's real `scopes` array
claim. This is a legitimate, functioning authorisation check ("is `locations:read` in the
id_token's `scopes` claim"), not a vestige of an IdP-group model aithne doesn't have.
Confirmed by reading the config directly — my first instinct on seeing a scope-request
fix land in the same commit was to suspect the allow-list had gone quietly inert; it
hadn't. Don't assume `ALLOWED_GROUPS` is dead weight just because aithne has no group
concept — check what `OIDC_GROUPS_CLAIM` points it at first.

## oauth2-proxy does NOT know to request app-specific scopes by default

oauth2-proxy's default scope-building logic requests `openid email profile` plus, if
`ALLOWED_GROUPS` is set, a literal extra `groups` OAuth scope (a Keycloak/Okta-style
convention — requesting the string "groups" as a scope switches on a groups claim).
aithne has no such `groups` scope, and oauth2-proxy has no built-in way to know it should
also request the actual authorisation scope (`locations:read`). Without an explicit
`OAUTH2_PROXY_SCOPE=openid email profile <domain:scope>` override, aithne's
granted-intersection algorithm (`handleAuthCodeGrant` — only returns the intersection of
requested-and-granted scopes, deliberately, so an RP can't silently receive scopes it
never asked for) correctly excludes the never-requested domain scope from every token —
**for every principal, regardless of grant**. This presents as "nobody can log in,
including legitimately-granted users" (locked out), not as a silent authz bypass — worth
distinguishing when triaging a report of this failure mode. Always set `OAUTH2_PROXY_SCOPE`
explicitly to include the real aithne scope name when `ALLOWED_GROUPS` gates on one.

## ES256 pinning — same gotcha as every other OIDC RP adoption

`--skip-oidc-discovery` means oauth2-proxy's `go-oidc` verifier never learns aithne's
`id_token_signing_alg_values_supported` and falls back to its OIDC-spec default of
RS256-only, rejecting aithne's ES256-signed tokens. Must set
`OAUTH2_PROXY_OIDC_ENABLED_SIGNING_ALGS=ES256` explicitly. Identical failure mode to
[[lucos-aithne-security-architecture]]'s BookStack/`lucos_worlds#21` incident — any new
generic OIDC RP integrated against aithne will hit this unless it's told about ES256
up front. Check for this explicitly whenever reviewing a new OIDC client adoption.

## Container-vs-browser endpoint split — same AITHNE_JWKS_URL precedent, now with a token endpoint too

Server-to-server code-for-token exchange is new territory (no prior aithne consumer did
this itself — they all verified pre-issued tokens locally). This PR introduces
`AITHNE_TOKEN_URL` as a sibling to the existing `AITHNE_JWKS_URL` convention (browser
needs `AITHNE_ORIGIN` for login redirect + `iss` validation; the container's own
token/JWKS calls need a container-reachable address, which differs from `AITHNE_ORIGIN`
in dev). Same pattern, one more env var. Expect this convention to keep extending as more
services do their own token redemption rather than just verifying pre-issued tokens.

## Deliberately deferred, not hidden: read/write scope split

`owntracks/recorder`'s `/api/0/kill` (deletes location history) is reachable under the
`locations:read`-gated path. Author added an explicit nginx `return 403` on that specific
sub-path as an interim mitigation and punted the "should `locations:read` split into
read/write scopes" question to lucas42/architect rather than deciding unilaterally.
**Minor residual on the interim mitigation, on record but not blocking:** the nginx deny
is a case-sensitive exact-prefix match; a case-normalisation bypass is theoretically
possible if `otrecorder`'s own routing turns out case-insensitive (not checked). Fold this
into whatever follow-up handles the read/write scope split rather than treating as a
separate finding — the author already flagged the gap transparently.

## Confirmed fail-closed in production: the 2026-07-09 crash-loop incident (lucos#265)

First real-world test of this design under failure, not just design review. PR #97 auto-
deployed ahead of its lucas42-only prod creds (`KEY_LUCOS_AITHNE`, `OAUTH2_PROXY_COOKIE_SECRET`)
→ oauth2-proxy crash-looped on `invalid configuration` (never bound its listener) → every
gated path 500'd for ~51 min. Verified fail-closed **architecturally**, not just from the
one observed 500: re-read the shipped `nginx.tmpl` and confirmed every gated location has
only `error_page 401 =403 /oauth2/sign_in;` — no `error_page 500 = ...` or any directive
that maps an `auth_request` failure to an allow outcome. nginx's `auth_request` module
returns 500 for any non-2xx/401/403 subrequest response by default, so a dead sidecar
structurally cannot fail open in this config. Device/MQTT split (independent
`auth_basic`/htpasswd on `/owntracks/pub`) held throughout, confirmed by the 401-not-500
distinction. Full review: [[lucos-aithne-jsclient-adr-review]] sibling note not applicable
here — this is the standalone incident-report review, posted via SendMessage to
lucos-site-reliability 2026-07-10, no PR review URL (report already merged as
lucas42/lucos#265). Follow-ups tracked on lucas42/lucos#266 (deploy sequencing/guard) and
lucas42/lucos_locations#99 (UX decision on the 403 sign-in page).

**Reusable check for the next sidecar-fronted service:** don't just accept "we observed a
500" as proof of fail-closed — pull the actual nginx/proxy config and confirm there's no
`error_page`/fallback directive that could turn an auth-check failure into an allow. A
crash-looping auth sidecar is exactly the scenario where a permissive misconfig would only
surface under failure, not in normal testing.
