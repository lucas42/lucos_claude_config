# lucos-developer Memory

## lucos_creds
- [Structure, SSH command syntax, deploy-snapshot gotcha](lucos_creds.md) — CRITICAL: `LUCOS_DEPLOY_ENV_BASE64` silently overwrites live store on redeploy

## lucos_photos
- [API/worker structure, test patching locations, content negotiation, face clustering](lucos_photos.md)

## lucos_photos_android
- [Detailed notes](android.md) — AGP 9.x migration, Robolectric/Conscrypt aarch64 issue, WorkManager test setup, MediaStore seeding, TikTok filtering, test commands

## lucos_monitoring
- [Erlang/rebar3 structure, EUnit tests, CircleCI v2 API, Erlang string pitfalls](lucos_monitoring.md)

## CircleCI
- [Heredoc << escaping](circleci_heredoc_escaping.md) — in v2.1 config, `<<` must be escaped as `\<<` in shell commands (even inside block scalars) or CI fails with "Unclosed << tag"

## Docker
- `docker` at `/usr/bin/docker`; always run `docker build` locally before pushing Dockerfile changes. See `~/.claude/references/docker-conventions.md`. Missing role suffix in container_name/image is a recurring review comment.
- **Healthcheck URLs: always `127.0.0.1`, never `localhost`** — Alpine resolves `localhost` to `::1`; services bind `0.0.0.0` (IPv4 only). Fixed in lucos_arachne#91, lucos_contacts#535.
- **`php:*-apache`**: has `curl` but not `wget` — use `curl -sf http://127.0.0.1/` for healthchecks.
- [FROM scratch + CA bundle](feedback_scratch_image_ca_bundle.md) — scratch images have no trust store; copy `ca-certificates.crt` (and `zoneinfo`) from builder the moment you add any outbound HTTPS call. Bit us in lucos_aithne#106.

## Python test stubs (sys.modules injection)
- [Stubbing patterns, pop-after-import, cross-file stub bleed](python_test_stubs.md) — CRITICAL: pop the server module too, not just stub names

## Java Mockito
- [Java Mockito — auth mocks](java_mockito_auth.md) — update ALL mock helpers (compareRequestResponse AND checkNotAllowed) when refactoring auth checks

## Key Rules (post-PR)
**Never call the merge API** — merging is handled by auto-merge or the user. **Always re-fetch PR review state** before reporting approval — memory drifts. **Report "PR approved" + URL only** — no supervised/auto-merge commentary.

## Alembic Autogenerate — Always Review Output
Always manually review generated migration files before committing. Autogenerate diffs against the local dev DB, which may be out of sync with the model history, producing noise operations (index drops, type changes) that are destructive in production. Only keep operations directly related to the current change.

## GitHub Repo Creation
- Apps don't have permission to create repos via GitHub API — use `gh repo create` (regular CLI).
- When creating a new repo for a PR workflow, push an empty initial commit to `main` first, then create the feature branch from it and open PR. (Orphan branches for main cause "no history in common" errors.)

## GitHub Actions: reusable workflow caller permissions
- [Required permissions + 2026-03-21 incident](github_actions_reusable_workflow_perms.md) — `permissions: {}` causes `startup_failure`; smoke test via `.github-test` before estate rollout

## lucos_repos Convention Checker
- [Draft-PR dry-run workflow, marking ready via GraphQL, audit app permissions](lucos_repos_convention_checker.md)

## lucos_loganne
- Node/Express app. Routes in `src/routes/`. Tests in `__tests__/routes.js` and `__tests__/auth.js` (Jest, `npm test`). `getEvents(since=null)` defaults to 7-day window. `src/auth.js` has the aithne JWKS serve-stale wrapper (lucos_loganne#555 / lucos_media_seinn#543 sibling).

## lucos_deploy_orb
- [Supervised repo — requires lucas42 approval](repo_supervision.md) — do NOT report as unsupervised; auto-merge does not trigger

## lucos_configy
- [Null serialisation for optional fields](configy_null_fields.md) — use `dict.get(key) or default`, not `dict.get(key, default)`; configy sends explicit `null` for absent optional fields

## TODO/FIXME Interpretation
- [Check for deferred intent before raising TODO as an issue](feedback_todo_deferred_intent.md) — "For now", "until X", "placeholder", "reserved for future" signals mean the author intentionally deferred; don't raise as actionable without design input

## Migration Script Patterns
- [Slug vs display name in eolas migrations](feedback_migration_slug_vs_name.md) — DB stores slugs (`"domestic-abuse"`), eolas stores display names (`"Domestic Abuse"`); always embed a `slugToName` table; caught in PR #268

## PR Process
- [Fresh review request after new commits](feedback_pr_new_commits.md) — pushing to an open PR requires a fresh SendMessage review request, not just a heads-up
- [Partial issue Closes keyword](feedback_partial_issue_closes.md) — use "Part of #N" / "Refs #N" when PR only fixes one of several root causes; save `Closes` for full resolution
- [Reporting PR completion: unsupervised vs non-unsupervised repos](feedback_pr_completion_reporting.md) — use different language depending on repo type
- [Check existing issues before filing](feedback_check_existing_issues.md) — search open issues first; other agents may have already filed the same finding
- [Grep for old name before renaming](feedback_rename_grep.md) — always `grep -r "old_name" .` before committing a rename; missed reference caused crash-loop + outage (lucos_arachne #267/#280)
- [Verify Dockerfile COPY when adding new files](feedback_dockerfile_copy.md) — check Dockerfile covers new dirs; `COPY *.py .` silently missed `ontologies/` dir (lucos_arachne #267/#282)
- [Refresh PR description with follow-up commits](feedback_pr_description_freshness.md) — if commit changes shape of work (passthrough vs hardcode, new dep, etc.) update description before re-requesting review
- [arachne find_entities labels](feedback_arachne_find_entities_labels.md) — returns `rdfs:label` not `skos:prefLabel`; use `get_entity(uri)` for canonical name
- [Dependabot recreate needs push access](feedback_dependabot_recreate.md) — GitHub Apps can't use `@dependabot recreate`; close the PR, flag to team-lead for lucas42 to post it
- [Avoid python -c apostrophe escaping](feedback_python_c_apostrophe_escaping.md) — use the Edit tool, not manually-escaped `'"'"'` bash tricks, for multi-line JS edits with apostrophes; shipped in a PR once
- [Verify dependency source matches pinned version](feedback_verify_dependency_source_matches_pinned_version.md) — check the installed version against the project's actual pin (fresh install/venv), not whatever's on host site-packages, before citing library internals as fact

## lucos_eolas
- [Migrations: always use ./update.sh](feedback_lucos_eolas_migrations.md) — never run makemigrations directly; script handles Docker build, migration gen, makemessages, and locale sync in one step

## lucos_aithne agent credentials
- [Per-agent principals + env-var naming](aithne_agent_credentials.md) — `LUCOS_<PERSONA>_AITHNE_CLIENT_SECRET` in `lucos_agent/development`; slug = personas.json slug; no shared `lucos_agent` identity (§4/§6)

## lucos_arachne ingestor
- [Entry points, triplestore helpers, skolemisation, diff path](lucos_arachne_ingestor.md)

## lucos_media_manager
- [Java/Maven structure, tag write path, test gotchas](lucos_media_manager.md)

## lucos_media_weightings
- [Test runner, tag format, recency logic](lucos_media_weightings.md)

## lucos_contacts
- [Django structure, test runner wiring, migration workflow](lucos_contacts.md)

## lucos_media_metadata_api
- [CodeQL #284 false-positive — SSRF guard is fetchEntityNameFromSource whitelist, not ValidateURIOrigin](lucos_media_metadata_api_ssrf_guard.md)

## Shell Scripts over SSH
Use `test -x /usr/sbin/tool` not `command -v tool` — `/usr/sbin` isn't in PATH on remote hosts. Caught in lucos_backups#269.

## lucos_media_seinn
- [forEach(async ...) is implicit parallelism](seinn_async_foreach_parallelism.md) — shared state mutations need serialisation; chain onto existing `evictionLock` rather than adding a second mutex
- `src/server/auth.js` has the aithne JWKS serve-stale wrapper (`createServeStaleJWKS` / `isJWKSInfraError`, lucos_media_seinn#543).

## lucos_backups
- [Architecture, config-from-configy pattern, rsync switch, tolerate_live_file](lucos_backups.md) — config.yaml is gitignored (generated from configy); new volume fields need changes in BOTH configy (Rust struct) and backups (Python reader)

## JWKS serve-stale estate rollout
Split from lucos_aithne#241 into per-consumer issues. **JS pattern**: wrap jose's `createRemoteJWKSet` in a `createServeStaleJWKS` helper that snapshots `.jwks()` after each success and falls back to `createLocalJWKSet(snapshot)` on an infra error. The issue's suggested snippet (`lastKnownGoodKeys = remoteJWKS`) is a no-op — don't carry it forward uncritically. `isJWKSInfraError` must classify by exact code (`ERR_JWKS_TIMEOUT`/`ECONNREFUSED`/`ENOTFOUND`), NOT `startsWith('ERR_JWKS_')` — the broad prefix also catches `ERR_JWKS_NO_MATCHING_KEY` (jose's post-retry genuine-unknown-kid error), which is not an infra failure. Done: lucos_media_seinn#543 (PR #552), lucos_loganne#555 (PR #564), lucos_notes#441 (PR #455), lucos_creds#446 (PR #447, "confirm-first" — creds had NEITHER a wrapper NOR infra-log distinction, worse off than the other three).
**Python/PyJWT pattern (lucos_photos#455, PR #465)**: `PyJWKClient` (>=2.13.0) has NO `jwk_set_data` attribute — that's from an older PyJWT version. Its real cache is `self.jwk_set_cache` (`JWKSetCache`). A subclass overriding `get_jwk_set` must maintain its own independent, non-expiring snapshot (`self._last_known_good`, set only on success) — reusing `self.jwk_set_data` fails with `AttributeError`, and the parent's own cache doesn't help either because `JWKSetCache.get()` returns `None` once its TTL (`lifespan`, e.g. 300s) elapses regardless of fetch outcome — NOT because of a self-wipe-on-failure bug (that exact bug WAS real in older PyJWT but was fixed as a security patch in 2.13.0 itself, GHSA-fhv5-28vv-h8m8 — don't claim it's still present without checking the actual pinned version's source, not whatever happens to be on the host Python's site-packages). lucos_photos already had a `_ResilientJWKSClient` that looked correct but referenced the nonexistent `jwk_set_data` attribute — undetected because its tests mocked `get_signing_key_from_jwt` directly (skipping `get_jwk_set` entirely) rather than exercising the real class. **Check any other Python/PyJWT consumer for the same `jwk_set_data` copy-paste bug before assuming "PyJWKClient-based = fine."** [[feedback_verify_dependency_source_matches_pinned_version]]
