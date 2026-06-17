---
name: lucos-aithne-security-architecture
description: Security architecture details for lucos_aithne — JWT/JWKS model, revocation window, machine key design, admin endpoints, known issues
metadata:
  type: project
---

# lucos_aithne security architecture (reviewed 2026-06-17)

## Token design
- **Algorithm**: ES256, pinned in both issuance and consumer verification. Algorithm-confusion attacks blocked.
- **TTL**: 15 minutes (`DefaultSessionTTL`). Cookie-based for humans (`aithne_session`, HttpOnly, Secure, SameSite=None, Domain=.l42.eu). Bearer for agents.
- **Audience**: estate-wide `l42.eu`. No per-service audience binding — scope enforcement is per-backend. ADR §6 is explicit: "A sensitive action must never be gated on bare 'is there a valid session?'"

## Signing key management
- EC P-256 keys, stored AES-256-GCM encrypted (KEK = `SIGNING_KEK`, 32-byte env var).
- 30-day rotation at startup; on-demand via `POST /admin/rotate-signing-key` (requires `aithne:admin`).
- **JWKS verification window = 15 min**: `ListVerificationKeys` returns old keys for 15 min after retirement so in-flight tokens remain verifiable.
- **SIGNING_KEK rotation requires `--rekey` first (#151 shipped, PR #174 merged).** You cannot just update the KEK in creds and redeploy — aithne will crash on startup because the stored signing keys are still wrapped with the old KEK. Correct sequence: stop service → `docker run --rekey` with SIGNING_KEK + NEW_SIGNING_KEK → update SIGNING_KEK in lucos_creds → restart service.

## Effective revocation window
- **Scenario A — Compromised machine key (client_secret)**: revoke credential + grant → attacker blocked from minting → existing tokens expire in ≤15 min JWT TTL + up to 5 min consumer JWKS cache = **≤20 min total window**. NOT driven by VerificationWindow.
- **Scenario B — Compromised signing key**: rotate signing key → old key stays in JWKS for VerificationWindow (30 min) + up to 5 min consumer JWKS cache = **≤35 min total window**.
- **Signing-key rotation does NOT shorten the Scenario A window** — the old key is still served in JWKS for 30 min (VerificationWindow). Signing-key rotation only helps in Scenario B.
- Runbook: lucas42/lucos_aithne#162 (merged in PR #165). PR #172 corrects Scenario B timing after PR #169 (VerificationWindow widened 15→30 min).

## Machine key authentication
- OAuth2 client_credentials grant: UUID v4 client_secret (122 bits entropy), stored as SHA-256 hash.
- **Known issue (already tracked)**: `string(c.Data) == secretHash` comparison is non-constant-time (lucas42/lucos_aithne#155). Low risk in practice (comparing hex-encoded hashes), but inconsistent with OIDC path which uses `subtle.ConstantTimeCompare`.
- Rate limiting on token endpoint: missing (lucas42/lucos_aithne#160). ADR commits to aithne owning this. UUID v4 entropy means brute-force is infeasible; DoS is the real risk.

## Admin endpoint security
- All `/admin/*` endpoints require `aithne:admin` scope via Bearer token (machine auth) or session cookie (browser UI).
- Attribution for all admin actions comes from verified JWT claims, not client-supplied fields.
- `requireAdminScope` (Bearer) for mutations; `requireAdminScopeFromCookie` (cookie) for GET browser pages.

## Session cookie CSRF model
- SameSite=None because cross-origin iframe SSO is a use case.
- Admin mutations use Bearer (not cookie) → not CSRF-vulnerable.
- Cookie-based consumer write endpoints need CSRF mitigation per local-verification-contract.md — checked in consumer migration checklist (lucas42/lucos_aithne#159).

## Per-agent principals (NOT a shared fleet principal)
- Each AI agent has its own `client_id` (slug e.g. `lucos-architect`) and `client_secret` stored in `lucos_agent/development`.
- Grant is per-principal, per-scope, per-environment. Default-deny.

## Known open issues (pre-estate-rollout)
- #155: non-constant-time machine key comparison (FIXED in PR #173 — subtle.ConstantTimeCompare)
- #160: no rate limiting on auth endpoints
- #159: consumer migration checklist
- #162: incident response runbook (FIXED in PR #165, timing corrected in PR #172)
- #150: per-token scope downscoping not supported (all granted scopes always in token)
- #151: SIGNING_KEK re-keying procedure (FIXED in PR #174 — --rekey subcommand)
- #148: dev/prod issuer model for local-dev human auth
- #156/#157/#158: local-verification-contract gaps
