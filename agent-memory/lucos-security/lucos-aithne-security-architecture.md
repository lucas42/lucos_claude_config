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

## Re-mint CORS policy (ADR-0003 §2) — conscious decision 2026-06-23

ADR-0003 specifies `*.l42.eu` glob for `/auth/remint` CORS. Implementation used explicit membership (OIDC-derived redirect_uris) based on an overcautious #181 review note that said "a glob is acceptable only as a conscious threat-model decision" but didn't make the call.

**The conscious call (made on #191):** The glob is safe. The endpoint is "harmless-if-forged" — a cross-origin trigger from an unregistered `*.l42.eu` origin can only refresh the victim's own session, and the attacker cannot read the HttpOnly response cookie or CORS-blocked response body. The only residual risk of the glob is a mild timing oracle (200 vs 401 reveals "user has an active aithne session"). Explicit per-consumer membership defended against a phantom threat.

**Implementation:** origin-suffix check (`strings.HasSuffix(origin, ".l42.eu")`), echo matched origin in `Access-Control-Allow-Origin` + `Allow-Credentials: true`.

**Load-bearing invariant:** The glob is ONLY safe while the endpoint remains "re-issue existing session only." Any future change adding a readable response body or externally-observable side-effect MUST also tighten the CORS policy. The warning in `remint.go` must be preserved.

**Tracked in:** lucas42/lucos_aithne#191.

## Local verification contract — scope enumeration prohibition

aithne's local verification contract (referenced in Wave 3 migrations) explicitly prohibits consumer services from enumerating the principal's currently granted scopes to the end user. This applies to error pages, API responses, and logs.

**Why this matters for Wave 3 services:**
- The JWT scopes are estate-wide (e.g. `aithne:admin`, `loganne:use`, `notes:use`, `media-manager:use`) — a single service's 403 page would expose the user's full access map across all services.
- The correct 403 message names only the *required* scope, not the *granted* scopes. "You lack `eolas:admin`" is sufficient — the user knows what they need, not what they have.
- Warning logs should also avoid logging the full scope list. Log only that the required scope was absent.

**Flagged during:** lucos_eolas#324 review (2026-06-26). lucas42 cited this as a known contract violation. I independently agreed and filed REQUEST_CHANGES.

**Pattern for Wave 3 403 responses:**
```
You are signed in but lack the <code>eolas:admin</code> scope needed to access this admin area.
```
No `Scopes granted: [...]` line. No scope dump in logs.

## Post-migration security review (2026-06-30)

**Fail-open vs fail-closed: FAIL CLOSED (correct).** All migrated services return 401/403 on auth failure. No fail-open behaviour found. The 5-min JWKS cache provides resilience during brief outages, but serve-stale is not implemented — a JWKS outage at cache-miss time causes a 401 storm (security-correct but more aggressive than the contract intends). See lucos_aithne#241.

**Decommission clean:** lucos_authentication is archived + NXDOMAIN. lucos_comhra also archived + NXDOMAIN. All actively-deployed Wave 3/4 services confirmed migrated on GitHub main. Residual: lucos_backups#361 (stale backup config entry, already tracked).

**Issues raised 2026-06-30:**
- lucos_router#100: Missing HSTS header in nginx config (LOW)
- lucos_aithne#241: JWKS serve-stale not implemented in any consumer (availability gap per contract §1)
- lucos_aithne#250: Wave 3 services missing principal_class allowlist check — **SUPERSEDED by #268** (see below)

**arachne MCP principal_class concern (memory 2026-06-16): RESOLVED.** arachne MCP uses scope gate (`arachne:read`), NOT principal_class alone.

## `principal_class` allowlist — REVERSED DECISION (2026-06-30)

lucas42 reversed the premise of #250: consumers MUST NOT hardcode a `principal_class` allowlist. Tracked in lucas42/lucos_aithne#268.

**Rationale accepted by security review:** Scope default-deny (ADR-0001 §6) already prevents a new class from silently gaining access — no explicit grant = scopeless token = rejected everywhere. The allowlist guards a door scope already locks, and its failure mode (estate-wide flag-day when a new class is legitimately introduced) is worse than the risk it mitigates.

**Do NOT raise `principal_class` allowlist absence as a finding** in any Wave 3/4 consumer. The contract §5 now explicitly says: `principal_class` is informational, consumers MUST NOT reject on absent/unrecognised class, scope is the sole gate.

Consumer cleanup tickets (removing hardcoded allowlists): lucas42/lucos_backups#363, lucas42/lucos_creds#430, lucas42/lucos_photos#456, lucas42/lucos_media_metadata_manager#357.

## Known open issues
- #148: dev/prod issuer model for local-dev human auth
- #241: JWKS serve-stale not implemented in consumers (raised 2026-06-30)
- #268: Flip contract §5 — principal_class allowlist removal + ADR-0001 §6 clarification

## ADR-0004 — source-controlled OIDC clients, creds-distributed secrets (APPROVED 2026-07-07, PR #286)

Committed `oidc_clients.json` (`//go:embed`, no secrets) reconciled into `oidc_clients` at startup; secrets delivered via `CLIENT_KEYS` env var from a lucos_creds linked credential (**Option B**: creds generates + distributes, aithne stays read-only against creds — no new write-edge, confirmed sound). Reconcile is **upsert-only, never deletes** (creds#333 empty-source lesson). `POST /admin/oidc-clients` removed entirely.

**Checked and confirmed fine:** unsalted hex-SHA256 secret hash is OK because `lucos_creds/server/src/storage.go` generates secrets as 32 random alphanumeric chars via `crypto/rand` (~190 bits) — salting only matters for low-entropy secrets.

**Flagged and resolved during review:** `POST`, `GET`, and `DELETE /admin/oidc-clients/{id}` are all one handler on one route (`main.go:1583-1584`, `handleAdminOIDCClients`) — removing "the endpoint" per §5 takes DELETE with it too. Combined with upsert-only-never-delete, there is no HTTP path left to *fully remove/decommission* an OIDC client post-merge — only `docker exec` + raw SQLite surgery (ADR-0002's already-accepted "host access = break-glass tier", not a new trust boundary). **Resolution (final commit f77b8b9b):** a narrow revocation-only `DELETE` was explicitly considered and **declined** — it would reintroduce exactly the admin write-surface §5 removes, and the leaked-secret case is already covered without any aithne endpoint by rotating the linked credential in creds (§4), which is creds-side and deploy-gated. So the residual host-DB-only gap is narrower than first framed: **full client decommission only, not day-to-day secret compromise.** Documented in ADR-0004 §5, Consequences→Negative, and Alternatives considered. Don't re-raise this as a gap in future aithne reviews — it's a conscious, reasoned, documented trade-off.

**Process note:** the PR head moved twice while I was mid-review (people pushing amendments live) — two of my APPROVEs landed (per GitHub's commit attribution) on a commit whose content differed from what my review text described. Re-diff against the *actual current head* before trusting your own prior review text on a fast-moving PR, don't assume the head is static between "read diff" and "post review."
