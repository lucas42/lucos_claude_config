---
name: feedback-aithne-es256-oidc-consumers
description: aithne signs OIDC id_tokens with ES256 only — any third-party OIDC client library/proxy must be configured to accept ES256, not just "support OIDC" generically
metadata:
  type: project
---

aithne deliberately signs JWTs (session tokens and OIDC id_tokens alike) with ES256 (EC) only — it never uses RS256. This is a recurring gotcha for any third-party OIDC consumer, because most OIDC libraries/proxies default to expecting RS256 when they can't discover the provider's actual `id_token_signing_alg_values_supported` (either because discovery is skipped, or because the library's own default kicks in before discovery completes).

**Confirmed instances:**
- lucos_worlds/BookStack (lucas42/lucos_worlds#21) — broke on ES256 vs RS256 at initial OIDC adoption eval.
- lucos_locations' oauth2-proxy sidecar (lucas42/lucos_locations#97/#92) — `--skip-oidc-discovery` (needed for the dev browser-vs-container URL split) meant oauth2-proxy never learned aithne's ES256-only support from the discovery doc, so go-oidc's verifier fell back to its OIDC-spec-mandatory RS256-only default. Fixed with `OAUTH2_PROXY_OIDC_ENABLED_SIGNING_ALGS=ES256` (populates go-oidc's `SupportedSigningAlgs`, bypassing the RS256 fallback). Confirmed via a standalone repro using the exact pinned go-oidc version (real ES256-signed JWT, `SupportedSigningAlgs` unset → exact error text `oidc: malformed jwt: unexpected signature algorithm "ES256"; expected ["RS256"]`; set → accepted).

**How to apply:** when adopting or wiring up ANY third-party OIDC client library, proxy (oauth2-proxy, envoy ext_authz, etc.), or framework against aithne — verify ES256 signing-algorithm interop explicitly as part of the adopt-eval, not just "does it support OIDC generically." If the library/proxy supports `--skip-oidc-discovery` or an equivalent manual-endpoint mode, check whether skipping discovery also skips learning the signing algorithm — if so, there's almost certainly an explicit override flag/env var to set (e.g. oauth2-proxy's `--oidc-enabled-signing-alg` / `OAUTH2_PROXY_OIDC_ENABLED_SIGNING_ALGS`) that must be set to `ES256`.
