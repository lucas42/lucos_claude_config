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

## JWKS serve-stale rollout COMPLETE (2026-07-09) — new residual gap on the incident runbook

lucos_aithne#241's serve-stale gap is now closed across all four planned JS consumers: lucas42/lucos_media_seinn#552, lucas42/lucos_loganne#564, lucas42/lucos_notes#455, lucas42/lucos_creds#447 (APPROVED by me). Each wraps `createRemoteJWKSet` with a snapshot-and-fallback helper, triggering only on exact transport-error codes (`ERR_JWKS_TIMEOUT`/`ECONNREFUSED`/`ENOTFOUND`) — deliberately excluding `ERR_JWKS_NO_MATCHING_KEY` (a genuine unknown-kid rejection, not an infra failure; misclassifying it was caught and fixed on the first two sibling PRs).

**Security verdict on the pattern itself: sound, and not a new risk for agent-secret/passkey compromise (Scenarios A/C in the runbook)** — serve-stale never touches the signing key, so those scenarios' existing ≤20-min window (see "Effective revocation window" above) is unaffected by whether the JWKS snapshot is fresh or stale.

**New residual specific to signing-key compromise (Scenario B):** the runbook's ≤35-min bound (30-min VerificationWindow + 5-min consumer cache) implicitly assumes every consumer can complete a fresh JWKS fetch within that window. A serve-stale consumer that specifically can't reach aithne's JWKS endpoint at the moment of an emergency `rotate-signing-key` keeps trusting its last-known-good snapshot (containing the compromised key) for as long as that reachability problem persists — unbounded by 30/35 min. Narrow compound-failure scenario (needs both an active key compromise AND a reachability problem specific to one consumer), but **lucos_creds is the worst possible target for it** — `creds:admin` unlocks every secret in the estate, not just one service.

Filed lucas42/lucos_aithne#306 (Low severity, non-blocking) recommending the runbook's Scenario B add an explicit "confirm/force serve-stale consumers have refreshed since rotation" step, naming lucos_creds as the one to verify first. Left open whether the fix should be a blanket restart-all-consumers step or a per-consumer reachability check — that's a judgement call for whoever picks it up, not decided in the issue.

**For future reviews:** don't re-raise "serve-stale weakens Scenario B" as a fresh finding in sibling consumer PRs (notes/loganne/seinn) — the mechanism is identical across all four and was already weighed here; only the *consequence* differs by what scope the consumer gates. #306 is the right place to track the runbook fix, not a new per-consumer issue.

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

## ADR-0004 implementation (PR #288, APPROVED 2026-07-07)

Implements #286's design exactly: `oidc_clients.json` (currently `[]`), `reconcileOIDCClients`/`parseClientKeysBySystem` in main.go, `Store.UpsertOIDCClient` (parameterized SQL, no injection risk), admin route cleanly removed (grepped whole repo, no dangling refs). Independently cloned + ran `go build`/`go vet`/`go test` myself (all pass, incl. new tests) rather than trusting the PR's self-reported checklist — worth doing on this repo specifically, see CI gap below. Also confirmed via SSH that `CLIENT_KEYS` is genuinely absent from `lucos_aithne/development`, matching the "safe no-op deploy" claim.

**Correction (2026-07-07):** I initially (wrongly) filed lucas42/lucos_aithne#289 claiming aithne's CI never runs `go test`/`go build`, based on checking only `.github/workflows/` (CodeQL + 2 auto-merge workflows). lucos-code-reviewer caught it: `.circleci/config.yml` has a real, deploy-gating `test` job (`go test ./...`, required by `lucos/deploy-avalon`) — confirmed via the `ci/circleci: test: success` status on PR #288. `go vet`-equivalent checks run implicitly as part of `go test`. Issue closed as invalid. **Lesson generalised to [[circleci-conventions]]: check `.circleci/config.yml` as well as `.github/workflows/` before asserting any lucos repo lacks a CI test gate** — GitHub Actions here is typically CodeQL/automation-only, CircleCI is the estate's real build/test/deploy CI.

## OIDC manifest has no per-environment redirect_uri scoping (found on PR #290, filed #291)

`oidc_clients.json` (ADR-0004) is one manifest shared by every deployment — `reconcileOIDCClients` upserts a client's full `redirect_uris` verbatim, no environment filtering. First real client (`lucos_locations`, #290) declares both a prod HTTPS redirect and a `http://localhost:8028/...` dev redirect in the same entry — once lucas42 wires the prod linked credential, **production aithne will accept the localhost redirect too**. Confirmed low severity, not blocking: `HasRedirectURI` is exact-match (no wildcard repointing) and `handleAuthCodeGrant` unconditionally requires `client_secret` (confidential-client-only, no PKCE-only path) — so capturing a code via a rogue local listener isn't enough to get a token without also holding the server-side secret. Exploiting it needs a local attacker already resident on the victim's machine. Still a real least-privilege gap that'll recur for every future client with both a prod and dev redirect. **Fixed in PR #292 (APPROVED 2026-07-07).** `reconcileOIDCClients` now takes `environment`; `isLoopbackRedirectURI`/`filterRedirectURIsForEnvironment` drop loopback redirect_uris (localhost + `net.IP.IsLoopback()`) unless `environment == "development"`; a client whose redirect_uris filter down to empty is skipped, not upserted broken. Independently rebuilt/retested — all pass. Known minor gaps in the filter (not blocking, PR-reviewed data not attacker input, exact-match `HasRedirectURI` unaffected either way): case-sensitive `"localhost"` match (misses `"LOCALHOST"`), and Go's `net.ParseIP` doesn't accept shorthand IPv4 (`"127.1"`). This class of issue is now closed for existing clients — no need to re-raise for future OIDC-client PRs unless the manifest entry itself looks wrong.

## Known open issues
- #148: dev/prod issuer model for local-dev human auth
- #241: JWKS serve-stale not implemented in consumers (raised 2026-06-30) — **CLOSED/rollout complete 2026-07-09**, see section above
- #268: Flip contract §5 — principal_class allowlist removal + ADR-0001 §6 clarification
- #306: Incident runbook Scenario B doesn't account for serve-stale consumers exceeding ≤35-min bound (raised 2026-07-09, Low, non-blocking)

## ADR-0004 — source-controlled OIDC clients, creds-distributed secrets (APPROVED 2026-07-07, PR #286)

Committed `oidc_clients.json` (`//go:embed`, no secrets) reconciled into `oidc_clients` at startup; secrets delivered via `CLIENT_KEYS` env var from a lucos_creds linked credential (**Option B**: creds generates + distributes, aithne stays read-only against creds — no new write-edge, confirmed sound). Reconcile is **upsert-only, never deletes** (creds#333 empty-source lesson). `POST /admin/oidc-clients` removed entirely.

**Checked and confirmed fine:** unsalted hex-SHA256 secret hash is OK because `lucos_creds/server/src/storage.go` generates secrets as 32 random alphanumeric chars via `crypto/rand` (~190 bits) — salting only matters for low-entropy secrets.

**Flagged and resolved during review:** `POST`, `GET`, and `DELETE /admin/oidc-clients/{id}` are all one handler on one route (`main.go:1583-1584`, `handleAdminOIDCClients`) — removing "the endpoint" per §5 takes DELETE with it too. Combined with upsert-only-never-delete, there is no HTTP path left to *fully remove/decommission* an OIDC client post-merge — only `docker exec` + raw SQLite surgery (ADR-0002's already-accepted "host access = break-glass tier", not a new trust boundary). **Resolution (final commit f77b8b9b):** a narrow revocation-only `DELETE` was explicitly considered and **declined** — it would reintroduce exactly the admin write-surface §5 removes, and the leaked-secret case is already covered without any aithne endpoint by rotating the linked credential in creds (§4), which is creds-side and deploy-gated. So the residual host-DB-only gap is narrower than first framed: **full client decommission only, not day-to-day secret compromise.** Documented in ADR-0004 §5, Consequences→Negative, and Alternatives considered. Don't re-raise this as a gap in future aithne reviews — it's a conscious, reasoned, documented trade-off.

**Process note:** the PR head moved twice while I was mid-review (people pushing amendments live) — two of my APPROVEs landed (per GitHub's commit attribution) on a commit whose content differed from what my review text described. Re-diff against the *actual current head* before trusting your own prior review text on a fast-moving PR, don't assume the head is static between "read diff" and "post review."

## Estate-wide algorithm pinning confirmed by direct code read (2026-07-08, lucos_worlds#21)

During the BookStack RS256/ES256 blocker (see [[risk-github-malware-bait-comments]] sibling issue same day for unrelated context — this is the `lucos_worlds#21` OIDC thread), read the actual verification code in every one of the 11 services that check aithne tokens: Python (`lucos_backups`, `lucos_photos`, `lucos_contacts`, `lucos_eolas`, `lucos_arachne` MCP) all pass `algorithms=["ES256"]` to PyJWT's `decode()`; JS (`lucos_notes`, `lucos_loganne`, `lucos_creds`, `lucos_media_seinn`, `lucos_arachne` explore) all use `jose`'s `jwtVerify` with the identical `algorithms: ['ES256'], // pin to ES256 — defence-in-depth against algorithm confusion`; PHP (`lucos_media_metadata_manager`) uses `JWK::parseKeySet($jwks, 'ES256')` + the modern Key-object `JWT::decode` path. This traces to a shared `local-verification-contract.md` in the aithne repo — a deliberate, estate-wide convention, not luck.

**Implication, stated honestly to lucas42 when asked directly:** algorithm-confusion is **not a live vulnerability today** — every consumer already independently hard-pins ES256, so even if aithne published a second (e.g. RSA) key, none of today's 11 consumers would accept a token claiming a different alg. The real argument for staying single-algorithm is more modest than "there's an active exposure": it's that having only one algorithm in existence is a **free, zero-effort safety net** that protects any future/careless integration automatically (one that forgets to pin, or uses a permissive off-the-shelf library trusting the discovery doc's algorithm list) — add a second algorithm and that free protection disappears, shifting safety onto "every future integrator must remember to pin correctly, forever." Don't restate the stronger "estate-wide precondition becomes live the moment a key is published" framing as a present-tense vulnerability claim in future reviews — it conflates key-exposure with actual exploitability against real consumers, which direct code inspection did not support.

**Unrelated to lucos_repos's own `jwt.Parse` hit in the same code search:** `lucos_repos/src/oidc.go` validates GitHub Actions' own OIDC tokens (`token.actions.githubusercontent.com`, genuinely RS256, GitHub's own JWKS) — a separate system, not an aithne consumer. Don't conflate it with the aithne-consumer set in future estate-wide JWT audits.

## Grants-read scope for the coordinator — disclosure verdict (2026-07-09, lucos_aithne#302)

Motivated by lucas42/lucos_locations#95 sitting stranded — no read path existed to verify a grant was already done, so a completed grant looked identical to an outstanding one. `GET /admin/grants?principal_id=Y&environment=Z` already exists (`listGrants`/`grantJSON` in main.go) but is `aithne:admin`-gated; `grantJSON` carries `scope`/`principal_id`/`environment`/`granted_by`/`granted_at`/revocation fields. `principal_id` is mandatory (400 without it) — but this is a weaker mitigation against a *compromised holder* of a new read scope than it looks, since agent principal IDs aren't secret (persona names, documented everywhere) — the real boundary is "only one principal holds the scope," not enumeration cost.

**Initial verdict (superseded — see below):** shape = boolean check only; coordinator-principal-only and dev-only were floated as *code-level* restrictions.

**lucas42's final decision on #302 overrode both staging restrictions** — don't cite the coordinator-only/dev-only framing above as current:
- **Refinement 1 — ships to every environment, not dev-first.** The whole point is verifying prod grants (that's what stranded lucas42/lucos_locations#95 in the first place); per-environment rollout was rejected as brittle.
- **Refinement 2 — principal-agnostic by design.** Gate purely on possession of the new `aithne:read` scope (or `aithne:admin`), **never on a hardcoded principal identity in code**. Who actually holds the scope (coordinator, for now) is a pure runtime grant decision, explicitly **not** to be baked into code or an ADR.

**Implemented + reviewed 2026-07-09 (PR #304, APPROVED):** `GET /admin/grants/check?principal_id=Y&scope=X` → `{"granted": bool}` only. Verified independently (not just re-read the design): `requireAdminScope`→`requireAnyScope` generalisation is behavior-preserving for all other admin routes; exact-match route (`/admin/grants/check`) correctly beats the `/admin/grants/` subtree under Go's `ServeMux` regardless of registration order; revoked grants excluded via `ListGrants(..., activeOnly=true)` → `WHERE revoked_at IS NULL`; missing-principal and real-but-ungranted-principal are structurally indistinguishable (same query path, no principals-table existence check) — no existence-oracle side channel; `#27` (the vocab entry for `aithne:read`) is a safe missing dependency since `requireAnyScope` only string-compares against token claims, no vocab lookup.

**New residual flagged on #304, accepted but on the record:** since `principal_id` is deliberately unrestricted (per Refinement 2 above) and both `principal_id` (contact IDs / persona slugs) and `scope` (the small, *public* `lucos_auth_scopes` vocab) are practically enumerable, an `aithne:read` holder could in principle cross-product-enumerate close to the full `GET /admin/grants` picture one boolean at a time. No rate limiting exists on `/admin/grants/check` or any other admin route (only the unauthenticated login/token-ceremony endpoints have limiters). Not a live concern while the sole grantee is the coordinator persona (the intended trust tier) — but **re-examine before `aithne:read` is ever granted to a broader or less-trusted principal**; a rate limit or audit log on this endpoint would be the natural mitigation at that point.

**Also confirmed while verifying (2026-07-09, re-confirmed against the actual `docker-compose.yml` on PR #304):** dev and prod aithne are fully separate containers/deployments with isolated SQLite volumes (single named volume per instance, no shared physical DB) — so `ListGrants`'s "empty environment matches all" behaviour can never actually leak cross-environment; one instance's DB only ever holds its own environment's rows. `createGrant` always stamps the instance's own `ENVIRONMENT` at creation-time. Not a live concern, but worth knowing before assuming the `environment` query param is a meaningful filter boundary.

Full assessment: architect's analysis + my verdict on the ticket, https://github.com/lucas42/lucos_aithne/issues/302. Implementation review: https://github.com/lucas42/lucos_aithne/pull/304.
