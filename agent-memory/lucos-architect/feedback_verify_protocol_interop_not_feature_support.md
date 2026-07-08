---
name: verify-protocol-interop-not-feature-support
description: When adopting a third-party app that integrates with a lucOS service, verify protocol-level interop (signing algs, token/claim formats), not just feature-level "it supports X"
metadata:
  type: feedback
---

When evaluating a third-party app to **adopt** (build-vs-adopt), and it must integrate with a lucOS service, verify **protocol-level interop**, not just that the feature exists on paper.

**Why:** In lucos_worlds ADR-0001 I chose BookStack substantially for its "native OIDC SSO / clean aithne integration" — but I only verified BookStack *supports OIDC* at the feature level (WebFetch of its OIDC docs: AUTH_METHOD=oidc, env vars, group mapping). I did **not** verify signing-algorithm interop. BookStack's OIDC hardcodes **RS256/RSA-only** (both `filterKeys()` and a hand-rolled `OidcJwtSigningKey` that throws "Only RS256 keys are currently supported"); aithne signs id_tokens **ES256-only** by deliberate, security-backed design (RFC 8725 algorithm-confusion posture — do NOT propose aithne multi-alg). Net: 100% key filter-out, login 500s, a **deployed** system nobody could log into, and a falsified ADR premise (lucos_worlds#21, 2026-07-08).

**How to apply:** For any adopt candidate that speaks to an estate service (auth especially, but also webhooks/Loganne, metadata APIs, search), before the ADR commits to it, verify the *wire contract* holds end-to-end: signing algorithms (ES256 vs RS256), token/claim shapes, content types, auth header formats. "It supports OIDC/SSO/webhooks" is a feature claim; "it accepts aithne's ES256 id_token" is the interop claim — and the second is the one that actually determines whether the integration works. Cheapest check: does the candidate's verification code / config accept the *specific* algorithm and format the estate service emits?

**Corollary — don't prescribe *spec-conformance* blind; verify the real client too.** Recommending a change to match a spec can *regress* against real clients that deviate from that spec. (2026-07-08, aithne#296: I suggested aithne `url.QueryUnescape` the Basic client creds per RFC 6749 §2.3.1 — but BookStack's `league/oauth2-client` `HttpBasicAuthOptionProvider` base64s the *raw* `id:secret` with NO urlencode (its docblock links the RFC but the code ignores it), so decoding would mangle any secret containing `+`/`%`. Had to walk back my own nit + CHANGES_REQUESTED it.) Before prescribing "do X to be spec-correct" on an interop boundary, check what the actual peer implementation does on the wire; a unit test that encodes-to-match-the-decode masks the mismatch.

**Durable estate facts from this incident:**
- BookStack (linuxserver/bookstack, incl. `development`) OIDC is **RS256/RSA-only**; no EC/ES256 in any version; no reverse-proxy/header auth method (`AUTH_METHOD` ∈ standard/ldap/saml2/oidc). `phpseclib3` (already a dep) supports EC, so a wrapper patch can add ES256 with vetted crypto. `AUTH_METHOD=standard` is the local-login stopgap when OIDC is broken. BookStack's OAuth2 client (`league/oauth2-client`) sends client creds via HTTP **Basic** (raw, un-urlencoded); aithne must accept `client_secret_basic` (RFC 6749 baseline), reading raw `r.BasicAuth()` values without url-decoding.
- aithne is **ES256-only and stays that way** — security-backed (alg-confusion blast radius is estate-wide the moment any RSA key enters the shared JWKS). Contain any RS256-only client's fix in the *leaf*, never bend aithne.

Related: [[project-lucos-worlds]], [[reference_aithne_next_param_full_url]].
