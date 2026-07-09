# lucos-security Agent Memory

## Standing Facts

- All lucas42 GitHub repos are **public** — committed docs, issues (incl. closed), and PR history are all publicly readable. Factor this into every finding.
- Security advisory routing rule and semver-major-ignore policy are documented in full in the persona file (`agents/lucos-security.md`) — don't duplicate here, just note deviations if any arise.

## Policies & Conventions (one-liners — see linked topic file for detail where present)

- **Advisory vs public issue** (lucas42/lucos#25, 2026-03-04): private advisory only if immediately network-exploitable AND unfixed; everything else is a public issue.
- **lucos-security PRs are not auto-merged** (lucas42/lucos#26): path is security raises PR → code-reviewer approves → auto-merge. Don't ask for lucos-security[bot] to be added to auto-merge conditions.
- **One finding per issue**, never omnibus (lucos_notes#149 split into #150–152).
- **CodeQL top-level `permissions` block** is a `lucos_repos` convention (lucos_repos#51), not a per-repo manual issue.
- **CodeQL supported languages only** — C/C++, C#, Go, Java/Kotlin, JS/TS, Python, Ruby, Swift. PHP not supported (lucos_media_metadata_manager#171). Detail: `codeql-supported-languages.md`.
- **CodeQL dismissal is the only false-positive mechanism** (no inline suppression, no `paths-ignore`). `lucos-security[bot]` has confirmed `security_events: write`. Detail: `codeql-dismissal-capability.md`, `codeql-false-positive-policy.md`.
- **Dependabot config convention** (lucos_repos#65): require `.github/dependabot.yml`, a `github-actions` entry with `directory: "/"`, `dependency-type: "all"` — don't check specific ecosystems per-repo.
- **Never propose semver-major Dependabot ignore rules** — major bumps should flow through; breakage → raise a CI-coverage issue instead (2026-04-18).
- **Open Questions must hard-gate triage** when a remediation value is unverified — a soft hedge gets approved anyway. Detail: `lesson-issue-body-open-questions.md` (root cause: lucos_repos#177 incident).
- **Ops check schedule** tracked in `ops-checks.md`.
- **Dev environments never hold a working prod credential**, in any form — hand-minted separate client, or a scoped/allowlisted creds link. Verified: creds-link scope is inert for OIDC client secrets (aithne authenticates by secret-hash, not link scope) — a "governed" exception can be worse than an honest bypass since it looks safe on review. Exception: lucos_contacts genuinely enforces link scope per-request, so a narrow compiled-code allowlist WAS approved there (creds#420). Detail: `policy-dev-prod-credential-containment.md`, `policy-creds420-write-exception.md`.

## Accepted Risks / Closed Findings (do not re-raise)

- **Vue 2 ReDoS** in vue-leaflet-antimeridian — accepted, no fix without Vue 3 migration (vue-leaflet-antimeridian#4, 2026-03-03).
- **Clear-text logging** in lucos_contacts_fb_import — accepted, script runs locally on the user's own data (lucos_contacts_fb_import#17, 2026-03-12).
- **`principal_class` allowlist absence** in Wave 3/4 consumers — do NOT raise; scope is the sole gate per aithne contract §5 (lucos_aithne#268). See `lucos-aithne-security-architecture.md`.
- **CircleCI token in query param** (lucos_monitoring) — fixed #25/#59, now `Circle-Token` header + v2 API.
- **Unauthenticated MCP endpoint** (lucos_arachne) — fixed PR #292, Bearer auth via `CLIENT_KEYS`; `/_info` still open.
- **DOMPurify XSS** (lucos_arachne) — fixed PR #52, `dompurify >= 3.3.2` override (GHSA-v2wj-7wpq-c8vv).
- **`safe_path` py/url-redirection** (lucos_photos) — false positive, mitigation already in place (lucos_photos#96).
- **eolas SSRF `go/request-forgery`** on `fetchEolasName` — false positive, dismissed (lucos_media_metadata_api PR #284). Detail: `lucos-media-metadata-api-eolas-ssrf-pattern.md`.

## Open Risk Patterns (watch for recurrence across repos)

- **Prompt injection via external text** (CI logs, issue/PR bodies) + **secrets leaking through CircleCI log masking**. Detail: `risk-prompt-injection-and-ci-logs.md`.
- **OS command injection via `os:cmd`** with unsanitised input — found in `lucos_monitoring/src/fetcher.erl` `checkTlsExpiry/1`; low exploitability today but fragile pattern to check for elsewhere.
- **Unauthenticated state-mutation endpoints** on internal services — `lucos_monitoring` `/suppress/*` (PUT/DELETE/POST) has no auth; network isolation is not a substitute for endpoint auth.
- **XSS via unescaped external data in manual HTML rendering** — `lucos_monitoring/src/server.erl` interpolates `techDetail`/`debug` unescaped; check any lucos service doing manual string-concat HTML.
- **lucos_creds `LUCOS_DEPLOY_ENV_BASE64`** silently reverts rotations of its own most-sensitive creds (`KEY_LUCOS_CREDS` etc.) unless the CircleCI snapshot is updated too. Detail: `lucos-creds-scoped-key-permissions.md`.
- **Clear-text-logging acceptance doesn't transfer between sibling repos** — `lucos_contacts_fb_import#17` was accepted because it's a local, one-off, user-run script; `lucos_contacts_googlesync_import` (issue #218, raised 2026-07-09) logs the same kind of data (phone numbers) but runs as an always-on production cron container — different exposure profile, needs its own accept/tighten decision, don't assume the fb_import precedent covers it.
- **JWKS serve-stale + signing-key compromise (Scenario B) window is unbounded per-consumer** — a consumer that can't reach aithne's JWKS endpoint during an emergency key rotation keeps trusting its stale (compromised-key-containing) snapshot indefinitely, beyond the runbook's ≤35-min figure. Approved anyway (lucos_creds#447, 2026-07-09) since it's estate-wide-contract-mandated and narrow/compound; tracked as a runbook fix on lucos_aithne#306, not a per-consumer finding. Don't re-raise per-consumer — see `lucos-aithne-security-architecture.md`.

## Topic Files (full detail)

- [Zombie Credentials risk](risk-zombie-credentials-downstream.md) — removing from CLIENT_KEYS doesn't revoke pre-registered downstream keys.
- [Webhook Fan-out Amplification](risk-webhook-fanout-amplification.md) — ~2× amplification via loganne fan-out; low risk currently.
- [Loganne Agent Access](reference-loganne-access.md) — bearer via KEY_LUCOS_LOGANNE; filter client-side; event type credentialUpdated.
- [lucos_aithne Security Architecture](lucos-aithne-security-architecture.md) — JWT/JWKS, ~20-min revocation window, machine key design; JWKS serve-stale rollout COMPLETE 2026-07-09 (4/4 consumers), new runbook gap tracked as #306.
- [Wave 4 CSRF / SameSite=None risk](risk-wave4-csrf-samesite-none.md) — @csrf_exempt + form-data mutations become CSRF-vulnerable when aithne_session (SameSite=None) replaces SameSite=Lax session. Check every Wave 4 PR.
- [aithne OIDC RP scope gap](aithne-oidc-rp-scope-gap.md) — CLOSED 2026-07-06: id_token/userinfo now carry `scopes` (#277/#280) atop access-token narrowing (#258/#279); generic OIDC RPs can gate on scope.
- [aithne OIDC url-redirect false positive](lucos-aithne-oidc-url-redirect-fp.md)
- [lucos_creds scoped key permissions + deploy-env-base64 risk](lucos-creds-scoped-key-permissions.md)
- [Issue-body Open Questions lesson](lesson-issue-body-open-questions.md)
- [Prompt injection & CI log secrets](risk-prompt-injection-and-ci-logs.md)
- [Relationships with teammates](relationships.md)
- [GitHub malware-bait comments](risk-github-malware-bait-comments.md) — throwaway-account + unsolicited-ZIP signature; `minimizeComment` GraphQL hides (not deletes) via lucos-security's App; attachment CDN URL needs a human GitHub abuse report.
- [Verify against real client behaviour, not just spec](lesson-verify-real-client-behavior.md) — approved a "RFC-correct" URL-decode fix (lucos_aithne#296) that broke against BookStack's actual OAuth2 client, which sends raw (non-encoded) Basic Auth credentials; pull the real counterparty's source before approving wire-format fixes. Now also covers runbook container-name claims (lucos_aithne#307) — verify against the real docker-compose.yml, not the plausible name.
- [oauth2-proxy fronting aithne pattern](reference-oauth2proxy-aithne-pattern.md) — lucos_locations#97: `OIDC_GROUPS_CLAIM=scopes` remaps ALLOWED_GROUPS to real scopes (not decorative); must set `OAUTH2_PROXY_SCOPE` explicitly or the domain scope is never requested (locks everyone out, not a bypass); same ES256-pinning gotcha as every OIDC RP; new `AITHNE_TOKEN_URL` convention for server-to-server token exchange.
