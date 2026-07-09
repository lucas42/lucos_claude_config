---
name: feedback-aithne-oauth2-proxy-scope-intersection
description: aithne's id_token "scopes" claim is the INTERSECTION of the OAuth2 scope= request and what's granted — oauth2-proxy's default "groups" scope convention doesn't work against it
metadata:
  type: project
---

aithne's `handleAuthCodeGrant` (the OIDC authorization_code token endpoint) deliberately narrows the id_token's `scopes` claim to the **intersection** of the OAuth2 `scope=` parameter the client requested at `/oauth2/authorize` and what the principal is actually granted — so a client can't silently receive scopes it never asked for. This means: **if the RP doesn't explicitly request a given aithne scope in its `scope=` parameter, that scope will never appear in the id_token even if the principal has been granted it.**

**Confirmed instance (lucos_locations#97/#92, oauth2-proxy)**: oauth2-proxy's OIDC provider defaults to requesting `openid email profile` plus, whenever `OAUTH2_PROXY_ALLOWED_GROUPS` is configured, a literal extra `groups` scope (`providers/oidc.go`: `if len(p.AllowedGroups) > 0 { oidcProviderDefaults.scope += " groups" }`) — a convention borrowed from IdPs like Keycloak/Okta where requesting the `groups` scope switches on a groups claim server-side. aithne has no such `groups` scope; its scope names *are* its authorisation scopes (e.g. `locations:read`). So the default request never intersects with what's granted, the `scopes` claim comes back empty, JWT/signature verification passes fine (see [[feedback_aithne_es256_oidc_consumers]] for that separate gotcha), and the RP's group/scope-gate then rejects the empty list — surfacing as an opaque `[AuthFailure] Invalid authentication via OAuth2: unauthorized` with no obvious link back to the scope-request mismatch.

**Fix**: set `OAUTH2_PROXY_SCOPE` explicitly to include the real aithne scope name(s), e.g. `OAUTH2_PROXY_SCOPE="openid email profile locations:read"`. Setting `--scope` bypasses oauth2-proxy's default+`groups` behaviour entirely — `setProviderDefaults` only applies the default when `p.Scope == ""`.

**How to apply:** when wiring up ANY OIDC client/proxy against aithne with a scope-based authorization gate (allowed-groups, allowed-roles, etc.), don't rely on the tool's default scope request — explicitly configure it to request the exact aithne scope name(s) the gate checks against. Verify by inspecting the actual `scope=` query parameter in the redirect to `/oauth2/authorize` (or equivalent), not just assuming the tool "handles OIDC scopes correctly" — most such tools' defaults are tuned for mainstream IdPs' generic-claim conventions, which don't match aithne's scope-name-is-authorization-capability model.
