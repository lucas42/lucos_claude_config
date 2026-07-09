---
name: bookstack-oidc-https-only
description: BookStack (lucos_worlds) OIDC hard-requires https issuer+endpoints; breaks local-dev login against http-localhost aithne
metadata:
  type: reference
---

BookStack's OIDC integration **hard-requires HTTPS** for the issuer and every
discovered endpoint (auth/token/userinfo), with no config toggle to relax it.
- `OidcProviderSettings::validateInitial()`: `if (!str_starts_with($issuer, 'https://')) throw InvalidArgumentException('Issuer value must start with https://')` — fires before any network call.
- `validate()` enforces the same `https://` rule on token/auth/userinfo endpoints; server-side calls use `CURLOPT_SSL_VERIFYHOST` (real cert verification, so self-signed fails without trust-store install).

**Symptom:** local-dev lucos_worlds login shows generic "An unknown error occurred". Real error in `/config/log/bookstack/laravel.log`: `Issuer value must start with https://`. Cause: dev aithne serves plain `http://localhost:8039`, so `OIDC_ISSUER=http://localhost:8039` is rejected instantly. **Dev-only** — prod aithne is `https://aithne.l42.eu`, login works.

Consequences for any local-dev OIDC handshake against BookStack: genuine local testing needs a TLS-terminating proxy in front of aithne with a locally-trusted CA (mkcert) installed into *both* the host browser and the `lucos_worlds_web` container trust store. Cheaper path for routine dev: `AUTH_METHOD=standard` + seeded local admin; exercise real OIDC in prod/staging.

Latent secondary gap: `lucos_worlds_web` compose lacks `extra_hosts: "host.docker.internal:host-gateway"` (aithne has it), so the container can't reach the host by name — only by raw gateway IP. Bites only once the https barrier is cleared. See [[reference_external_access_to_lan_host]]. (Raised as lucas42/lucos_worlds#36 — low/latent.)

**2026-07-09 decision (lucos_worlds#35):** lucas42's "Option 3" (point dev worlds issuer at *prod* aithne `https://aithne.l42.eu`) is **blocked by a lucos_creds guardrail** — a non-prod env may only link to a prod credential when the scope is `:read`; the OIDC client secret isn't read-only, so dev can't hold it (`Validation Error: only read-only scopes ... permitted on a link from non-production to production`). The guardrail is correct: dev must not hold a working prod-aithne secret. A *separate* hand-minted dev OIDC client is NOT a way round it (security concur): minting+hand-copying a secret bypasses the link-validation mechanism entirely (agents have dev write access), degrading an enforced invariant to a convention; and there's no internal trusted network so "localhost redirect_uri only" is load-bearing. BookStack mandates a client secret (`$required=['clientId','clientSecret','issuer']`) so no PKCE public-client escape. **Resolution options:** (1) `AUTH_METHOD=standard` in dev — unblock now, zero prod exposure, but dev never exercises real OIDC; (2) serve *dev* aithne over HTTPS via mkcert — correct root-cause fix, but aithne's issuer = single `APP_ORIGIN` (`oidc.go`), so it changes the issuer for EVERY dev OIDC consumer + needs CA trust in each consumer container ⇒ an **aithne dev-infra initiative**, not a worlds ticket. Recommended: Opt 1 now, Opt 2 as a separate strategic initiative (its payoff is estate-wide dev OIDC fidelity — the ES256/client-auth/email class of bug caught late in prod).
