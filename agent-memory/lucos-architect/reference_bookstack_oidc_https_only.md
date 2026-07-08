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

Latent secondary gap: `lucos_worlds_web` compose lacks `extra_hosts: "host.docker.internal:host-gateway"` (aithne has it), so the container can't reach the host by name — only by raw gateway IP. Bites only once the https barrier is cleared. See [[reference_external_access_to_lan_host]].
