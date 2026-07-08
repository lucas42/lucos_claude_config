---
name: lucos-worlds-bookstack-deploy
description: Lessons from the lucos_worlds (BookStack) deploy and its ES256 OIDC patch — DB password/volume-init gotcha, APP_KEY formatting, the BookStack/aithne RSA-vs-ES256 fix (phpseclib3 mechanics, wrapper≠not-a-fork), CircleCI setup_remote_docker/bind-mount incompatibility, and required-status-check ordering
metadata:
  type: project
---

## MariaDB/MySQL: password changes after first init don't take effect

MariaDB (and MySQL) only run their init logic — creating `MARIADB_USER`/`MARIADB_PASSWORD`, creating the database — **once, against an empty data directory**. If a container first boots with an empty or wrong password value, the app user is silently skipped (no error, container reports `healthy` anyway) or created with the wrong password. Setting the correct value in creds afterward and just redeploying does **not** fix it — the persisted volume already has a data directory, so init never reruns.

**Symptom:** `Access denied for user 'X'@'...' (using password: NO)` (user never created) or `(using password: YES)` (user created, but with a stale password that no longer matches creds — happens if the creds value changes again after a successful init).

**Fix:** stop the DB container, `docker volume rm` the DB data volume, redeploy. Only safe when the volume has no real data yet (first-ever deploy) — this is exactly the `recreate_effort` judgment call the backup-diligence habit exists for.

**Why this happened twice in one deploy:** DB_PASSWORD was set in prod creds, but its *value* changed again (lucas42 re-set it) after the first successful init — both containers agreed on the new value, but the value baked into the DB from init was the old one. Same root cause, different trigger. If DB_PASSWORD is going to be touched more than once during a rollout, always re-verify actual DB auth (not just "the env var is now set") before declaring done.

## Laravel `APP_KEY` needs the literal `base64:` prefix

`APP_KEY=<44-char base64 string>` (no prefix) causes Laravel to treat the value as 44 *raw* bytes rather than base64-decoding to 32 bytes — `Unsupported cipher or incorrect key length`. The value must be exactly `base64:` + `openssl rand -base64 32` output, with `base64:` as the literal first 7 characters. This bit us twice: once in local testing, once in prod even after documenting it in the repo README — the README note alone didn't prevent the mistake at credential-setting time. When handing off an APP_KEY-generation instruction, give the exact one-liner (`base64:$(openssl rand -base64 32)`), not just prose.

## BookStack ↔ lucos_aithne: OIDC ES256/RS256 mismatch — RESOLVED via a narrow patch (lucas42/lucos_worlds#26/#28, merged 2026-07-08)

**Root cause (still true, keep for future "adopt a tool + wire to aithne OIDC" ADRs):** BookStack hardcodes RSA/RS256-only OIDC key acceptance in **three** independent places — `OidcProviderSettings::filterKeys()` (discovery filter), `OidcJwtWithClaims::validateTokenSignature()` (token-verification gate, checks the token's own `alg` header separately), and `OidcJwtSigningKey::loadFromJwkArray()`/`loadFromPath()` (key construction — builds an RSA key from JWK `e`/`n`, or a PEM file, respectively). `lucos_aithne` signs exclusively with ES256 (EC/P-256). No BookStack version (including `development` HEAD) or config path (`OIDC_PUBLIC_KEY` enforces the same RSA-only check) works around this. Two BookStack theme hooks exist for OIDC (`OIDC_AUTH_PRE_REDIRECT`, `OIDC_ID_TOKEN_PRE_VALIDATE`) but neither can fix this — the failure happens on the first line of `OidcService::login()`, before either hook fires, and `OIDC_ID_TOKEN_PRE_VALIDATE` only lets you replace claims data, not signature verification. **Check any future OIDC-RP tool's supported signing algorithms against ES256 before adopting it** — this exact gap can recur with any RSA-only OIDC client library.

**Fix shipped:** patched all three files to also accept EC/P-256/ES256, delivered via a plain `Dockerfile COPY` (not `custom-cont-init` — `/app/www` isn't volume-backed, unlike `/config`). Uses BookStack's already-vendored `phpseclib3` — no new dependency. Key mechanics, useful for any future JWT/JWK work in PHP:
- Load an EC JWK via `PublicKeyLoader::load(json_encode($jwk))` — phpseclib3 auto-detects the JWK format from a JSON **string** (not a raw PHP array, unlike the RSA `e`/`n` path).
- `getCurve()` on a loaded EC key returns phpseclib3's internal curve name (`secp256r1` for what JWK calls `P-256`) — check curves against `'secp256r1'`, not `'P-256'`.
- JWT ES256 signatures are raw R‖S (IEEE P1363), not phpseclib3's ASN.1 DER default — set `.withSignatureFormat('IEEE')` on the loaded key.
- **Patch both EC-loading code paths equally** (JWK-array *and* file:// PEM) — security review caught that only the JWK-array path had the curve restriction; the file:// path (`OIDC_PUBLIC_KEY` config) accepted any curve with zero restriction. Currently-dead code in a deployment doesn't mean risk-free — it's one env var away from being live.

**"Wrapper" delivery ≠ not-a-fork.** Whether a source patch is baked into the image at build time or copied in at container start via `custom-cont-init`, you're authoring and owning modified vendored files either way — same re-verification-on-every-upstream-bump commitment. Don't let "it's in our wrapper layer" framing obscure that from a stakeholder who's specifically averse to forking.

**Verification-first discipline for a security-critical patch, in order:** (1) isolated crypto check outside the app — independently generate a keypair + real signed token, confirm the patched verify() logic accepts valid / rejects tampered, before wiring into the app at all; (2) a real end-to-end integration test (mock IdP + the actual patched image, not a unit test) exercising the full login flow; (3) the integration test **must include a negative-path scenario** (deliberately tampered signature must be rejected) — the happy-path-only version of this test passed locally for hours before a reviewer pointed out it couldn't catch "verification became too permissive," which is the actually-dangerous direction for auth code to regress in. Cheap to add (flip a byte in the mock IdP's signature via a test-only control endpoint) but easy to skip if you're only thinking about "does login work," not "can this fail open."

## CircleCI `setup_remote_docker` + `docker-compose` bind-mounts don't mix

`setup_remote_docker` runs the Docker daemon on a **separate remote host** that has no access to the CircleCI job's checked-out filesystem. A `docker-compose.yml` `volumes:` bind-mount (`./some-file:/container/path`) that works perfectly locally will silently resolve to an **empty directory** on that remote host — Docker's classic "create the mount point if the source doesn't exist" behavior, except the source path genuinely doesn't exist there at all. Symptom: a script expected at that mount point fails with `Is a directory` (or similar) only in CI, never locally.

**Fix:** anything that needs to reach the build/runtime environment in a `setup_remote_docker` job must be delivered via `COPY` in a Dockerfile (build context gets uploaded to wherever the build actually runs), never a compose bind-mount. If you need to layer test-only content (e.g. trusting a self-signed cert) on top of an existing image build, use a second build stage (`ARG BASE_IMAGE` / `FROM ${BASE_IMAGE}` in a separate Dockerfile) rather than a bind-mounted `custom-cont-init` script, and orchestrate the two-stage build explicitly (a small shell script calling `docker build` twice) rather than relying on docker-compose's single-stage declarative `build:`.

## Process gap: don't add a required branch-protection status check before the emitting job exists on the target branch

Two variants of the same mistake, both in this one PR sequence:
1. **On a from-scratch repo**, branch protection wasn't set up before the first PR — `lucos-code-reviewer`'s approval fired auto-merge with no required check to wait on, merging before CI even finished.
2. **Adding a brand-new CircleCI job as a required check on the SAME PR that introduces it** blocks every *other* PR against that branch — their CI runs against the pre-existing config (no such job defined), so the required status can never be reported for them, and GitHub blocks merge waiting for a status that will never arrive. This stalled an unrelated, already-approved PR (lucos_worlds#27) with no visible cause until traced via the commit-status API.

**Correct order:** add the CI job first (a normal, non-required check), let it merge to main, confirm it reports successfully on main's own post-merge CI run, **then** add it to `required_status_checks.contexts`. If you must gate the same PR that introduces the job, temporarily relax the requirement for any *other* queued PRs, and restore it only after your job actually exists on the target branch and has been proven to report.
