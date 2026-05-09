# lucos-developer Memory

## lucos_creds

- **Server**: Go SSH/SFTP server in `server/src/`. Tests run with `/usr/local/go/bin/go test ./src`.
- **UI**: Node/Express in `ui/src/index.js`, EJS views in `ui/src/views/`. No UI tests.
- **SSH command syntax**: `system/env/KEY=value` (set), `system/env/KEY=` (delete simple), `client/env => server/env` (create linked), `rm client/env => server` (delete linked), `ls` / `ls system/env` / `ls system/env/KEY` (read).
- **CI**: CircleCI runs Go tests in parallel with Docker build. Config in `.circleci/config.yml`.
- **`/usr/local/go/bin/go`** is the Go binary path (not on PATH in bash tool sessions).
- Linked credential DB schema: UNIQUE on (clientsystem, clientenvironment, serversystem) — serverenvironment not part of the unique key.
- **CRITICAL — deploy reads a snapshot, not live store**: `LUCOS_DEPLOY_ENV_BASE64` in CircleCI is a base64-encoded `.env` snapshot used to break the circular self-deploy dependency (tracked in lucos_creds#152). It is manually maintained and **silently overwrites the live store on every redeploy**. If you update credentials in the live store but a redeploy happens, the old values come back. When a live-store fix "doesn't take" after a redeploy, check for `*_DEPLOY_*` / `*_ENV_BASE64` env vars in CircleCI — that's the snapshot path. Both the live store AND the CircleCI env var must be updated. (Incident: 2026-05-09-creds-ssh-key-crlf)
- **SSH key corruption: `Load key … error in libcrypto`** surfaces for any non-base64-alphabet byte in the PEM body — CRLF (`\r\n`), `~` (old substitution encoding), literal `\n`, BOM, extra whitespace. Don't narrow to one corruption mode early when diagnosing.

## lucos_photos

- **API**: FastAPI. Entry: `api/app/main.py` (slim — app factory only). Domain modules: `auth.py`, `database.py`, `redis_client.py`, `serializers.py`, `services.py`, `routers/` (photos, people, faces, telemetry, webhooks, app_release). Tests in `api/tests/`. Run with `cd api && python3 -m pytest`.
- **Shared `get_db`**: All routers import `get_db` from `app.database`. Tests override via `app.dependency_overrides[get_db]`. Patching `SessionLocal` in tests: patch BOTH `app.database.SessionLocal` AND `app.main.SessionLocal` (used by `check_db`/`get_metrics`).
- **Test patching module locations**: auth functions → `app.auth.*`, Loganne/contacts clients → `app.routers.people.*` or `app.routers.faces.*`, DERIVATIVES_DIR for serializer → `app.serializers.DERIVATIVES_DIR`, app release cache → `app.routers.app_release.*`, httpx in auth → `app.auth.httpx.AsyncClient`.
- **Model JSON type**: Use SQLAlchemy `JSON` (not `JSONB`) in models — `JSONB` is Postgres-only and breaks SQLite in-memory tests.
- **Auth pattern for M2M endpoints**: use `verify_key` dependency (same as `POST /photos`). `verify_session` is for browser/cookie auth only.
- **Some tests hang** when run together — `test_main.py::TestUpload` calls `emit_loganne_event` which tries to connect to the real Loganne service. This is pre-existing; run `tests/test_telemetry.py` and `tests/test_photos.py` separately for fast feedback.
- **CRITICAL: test_photos.py patches `app.routers.photos.PHOTOS_DIR`** (not `app.main`). This file can't be completed locally due to Loganne hang — always check CI passes to catch test_photos.py failures.
- **Worker**: Entry point `worker/app/main.py`. RQ worker on queue `"photos"`. Tests in `worker/tests/`. Run with `cd worker && python3 -m pytest`.
- **Shared**: `shared/lucos_photos_common/` — `database.py` (SQLAlchemy engine), `models.py` (ORM models), `jobs.py` (RQ job handlers: `process_photo`, `reprocess_photo`).
- **Job handlers in shared**: Both API (enqueue) and worker (execute) import from `lucos_photos_common.jobs`. Avoids string-based module path references.
- **API tests use SQLite in-memory** via `conftest.py`; Redis unavailability is non-fatal — `enqueue_process_photo` catches exceptions.
- **Worker tests patch `lucos_photos_common.jobs.SessionLocal`** directly to inject SQLite sessions.
- **CI**: Two test jobs — `test-api` and `test-worker` — run in parallel with `lucos/build-multiplatform`.
- `python3` is the binary (not `python`) in the local shell environment.
- **Upload auth**: `Authorization: key <API_KEY>` header; `CLIENT_KEYS` env var is semicolon-separated `name=value` pairs.
- **Deduplication**: Server uses SHA256 — returns 200 if duplicate, 201 if new.
- **Content negotiation**: `GET /photos/{uuid}` uses `python-mimeparse`. `best_match(["text/html", "application/json"], accept)` — mimeparse resolves ties (e.g. `*/*`) to the **last** item in the list, so put JSON last to make `*/*` default to JSON.
- **`emit_loganne_event`** accepts an optional `url` param (passed through to `updateLoganne`). Photo-specific events should include `url=photo_url(photo.id)`.
- **`photo_url(photo_id)`** helper in `main.py` builds absolute URL using `APP_ORIGIN` env var.
- **Face clustering**: `cluster_faces()` in `shared/lucos_photos_common/jobs.py`. DBSCAN with `min_samples=1` (every face forms at least a cluster of 1 — intentional, we want every face assigned). `scikit-learn==1.8.0` in `worker/requirements.txt`. `_sync_photo_person()` in `jobs.py` mirrors `sync_photo_person()` in `api/app/main.py` — duplication tracked in lucos_photos#145.
- **Always emit Loganne events for both sides of a state change** — if link emits `personContactLinked`, unlink must emit `personContactUnlinked`. Missing the inverse is a common review catch.
- **`lucos_search_component`**: npm package `lucos_search_component@^1.0.14`. No Docker image — add a `node:22-alpine` build stage to Dockerfile, install via npm, copy `dist/index.js`. Use `<span is="lucos-search" data-api-key="..." data-types="Person">`. `KEY_LUCOS_ARACHNE` must be declared in docker-compose.yml environment AND `.env.example`.
- **HTML server-side key injection**: `/people` page uses `open(file).read().replace("__ARACHNE_KEY__", key)` pattern for injecting env vars into static HTML at route handler time. Content negotiation same as `/photos/{id}`: `mimeparse.best_match(["text/html", "application/json"], accept)`.
- **Always check `docker-compose.yml` when adding a new env var** — new vars consumed in code must also be declared in the `environment:` section of the relevant service, and in `.env.example`.

## lucos_photos_android

- [Detailed notes](android.md) — AGP 9.x migration, Robolectric/Conscrypt aarch64 issue, WorkManager test setup, MediaStore seeding, TikTok filtering, test commands

## lucos_monitoring

- **Language**: Erlang, built with rebar3. Key logic in `src/fetcher.erl`.
- **Tests**: EUnit tests in each `.erl` file inside `-ifdef(TEST)` block. No Erlang locally — tests run in CI only.
- **CircleCI check**: Uses v2 API — fetches pipeline via `/project/{slug}/pipeline?branch=main`, then workflows via `/pipeline/{id}/workflow`. Auth via `Circle-Token` header (not query param like v1.1).
- **Workflow statuses**: `failed` → red, `success`/`running`/`on_hold` → green.
- **`checkWorkflowStatuses/4`**: Pure function, fully unit-testable without HTTP mocks.
- **Erlang string pitfalls**: `re:replace(..., {return, list})` returns an iolist (nested list), not a flat string. Always wrap with `lists:flatten/1` before using `++`. Similarly, `lists:join/2` returns an iolist — use `string:join/2` instead when a flat list is needed for `++` concatenation.
- **`httpc` status matching**: status code is an integer (e.g. `200`), not a partial pattern. Use a guard: `when StatusCode >= 200, StatusCode < 300` — not `{_, 2, _}`.

## CircleCI

- [Heredoc << escaping](circleci_heredoc_escaping.md) — in v2.1 config, `<<` must be escaped as `\<<` in shell commands (even inside block scalars) or CI fails with "Unclosed << tag"

## Docker — Local Builds

`docker` is available at `/usr/bin/docker` and the daemon is running. Always run `docker build <context>` locally before pushing Dockerfile changes — do not rely on CI to catch build failures.

## Docker Conventions

See `~/.claude/references/docker-conventions.md` for canonical Docker conventions (container naming, volumes, healthchecks). Missing the role suffix in container_name/image is a recurring review comment — check docker-compose.yml before opening any PR.

- **Healthcheck URLs: always use `127.0.0.1`, never `localhost`** — Alpine resolves `localhost` to `::1` (IPv6) but services bind `0.0.0.0` (IPv4 only). Using `localhost` causes healthchecks to fail silently. Fixed in lucos_arachne#91 and lucos_contacts#535.
- **`php:*-apache` images include `curl` but NOT `wget`** — use `curl -sf http://127.0.0.1/` for healthchecks, no Dockerfile install step needed. `-f` treats HTTP errors as failures (wget doesn't do this by default).

## Python test stubs (sys.modules injection)

When stubbing modules via `sys.modules` before importing a server module in tests:
- **Always pop stubs after import** (`sys.modules.pop(mod_name, None)`) if other test files in the same pytest session import the real module — stale stubs cause `ImportError` on real module attributes.
- **waitress**: must stub `waitress` with `stub.serve = lambda *a, **kw: None` for WSGI servers using waitress.
- **Pattern** (for pytest files): save stub names list before import, pop after import.
- **CRITICAL: pop the server module too** before installing stubs if multiple test files all use `sys.modules` stubs and import the same server module. If test_auth.py imports server (caching it in sys.modules with its empty stubs bound to globals), then test_webhook.py's stubs will NOT bind — server.py's module globals still point to test_auth.py's stubs. Fix: `sys.modules.pop("server", None)` at the top of test_webhook.py before stub setup. Failing to do this causes `KeyError` on `live_systems[event["source"]]` and similar (values are `{}` from the earlier stub).
- **Stub must include ALL functions imported in server.py** — missing one (e.g. `merge_items_in_triplestore`) causes `ImportError` before cleanup code runs, leaving ALL stubs in `sys.modules` and cascading failures into subsequent test files.

## Java Mockito — Phase-dependent auth mocks

When refactoring auth checks in Java controllers, ALL mock-creating helpers must be updated:
- `compareRequestResponse` — mock helper, needs auth setup
- `checkNotAllowed` — separate mock helper, easy to miss
If switching from `hasAuthorizationHeader() && !isAuthorised()` (Phase 1) to `!isAuthorised()` (Phase 3), add `when(request.isAuthorised()).thenReturn(true)` to BOTH helpers.

## Never Merge PRs — and Never Report Post-Approval State Without Checking

**STOP. Do not call the merge endpoint.** Never call the merge API on any PR — merging is handled by auto-merge (GitHub) or the user, not agents.

**"Supervised" means agents cannot *approve* PRs — it does NOT prevent auto-merge.** Even on supervised repos (`unsupervisedAgentCode: false`), a PR will auto-merge after lucas42 approves it. Do not report "awaiting lucas42 merge" as if auto-merge won't happen.

**Always query the GitHub API for actual PR state before reporting it.** Conversation memory drifts within minutes — a PR you think is open may already be merged. Never report state from memory.

**After approval: report "PR approved" + the PR URL. Nothing else.** Do not say "awaiting lucas42", do not say "auto-merging". Just report approved and the URL.

## Alembic Autogenerate — Always Review Output

Always manually review generated migration files before committing. Autogenerate diffs against the local dev DB, which may be out of sync with the model history, producing noise operations (index drops, type changes) that are destructive in production. Only keep operations directly related to the current change.

## GitHub Repo Creation

- Apps don't have permission to create repos via GitHub API — use `gh repo create` (regular CLI).
- When creating a new repo for a PR workflow, push an empty initial commit to `main` first, then create the feature branch from it and open PR. (Orphan branches for main cause "no history in common" errors.)

## GitHub Actions: caller workflow permissions for reusable workflows

**`permissions: {}` causes `startup_failure`** on any caller that uses `uses:` to call a cross-repo reusable workflow. GitHub needs at least `contents: read` to fetch the reusable workflow definition. This applies to ALL caller workflows, not just dependabot.

**Minimum correct caller pattern for code-reviewer-auto-merge:**
```yaml
permissions:
  contents: read
```

**Minimum correct caller pattern for dependabot-auto-merge** (confirmed via smoke test in lucas42/.github-test):
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  pull-requests: write
  contents: write

jobs:
  dependabot:
    uses: lucas42/.github/.github/workflows/dependabot-auto-merge.yml@main
```

- Use `pull_request` (not `pull_request_target`) for dependabot
- Top-level `permissions:` block is required — `{}` or omitting it causes `startup_failure`
- No `secrets: inherit`, no `if:` guard in caller (guard lives in the reusable workflow)
- Workflow conclusion for non-Dependabot PRs is `skipped` (not `success`) — both are passing

**CRITICAL: Smoke test before estate rollout.** Any change to a caller workflow template must be smoke-tested via `.github-test` PR + full `lucas42/.github` smoke test suite BEFORE the estate-wide rollout. Skipping this step caused the 2026-03-21 incident where `permissions: {}` was rolled out to 45 repos, breaking auto-merge on all of them. The full smoke test suite is triggered by opening a PR against `lucas42/.github`.

## lucos_repos Convention Checker

- `lucos-developer` app cannot update `.github/workflows/` files — lacks `workflows` permission. Use `lucos-system-administrator` for bulk workflow file updates across repos.
- Convention dry-run diff: open a DRAFT PR first, wait for the audit dry-run comment, verify diff matches expectations, then mark ready for review.
- **Marking draft PR ready**: use `~/sandboxes/lucos_agent/gh-as-agent --app lucos-developer graphql -f query='mutation { markPullRequestReadyForReview(input: {pullRequestId: "PR_NODE_ID"}) { pullRequest { isDraft } } }'`. The REST PATCH endpoint silently ignores `draft: false`. Do NOT use `gh-projects` for this — it only has `project` scope.
- **Audit app permissions**: the audit app has `contents: read` but NOT `secrets` permission. Conventions must not call `GET /repos/{owner}/{repo}/actions/secrets` — use workflow file content checks instead.

## lucos_loganne

- Node/Express app. Routes in `src/routes/`. Tests in `__tests__/routes.js`. Run with `npm test`.
- `getEvents(since=null)` in `routes/events.js` — defaults to `DEFAULT_VIEW_WINDOW_MS` (7 days) when `since` is null. Both websocket catch-up and `GET /events` use this default.

## lucos_deploy_orb

- [Supervised repo — requires lucas42 approval](repo_supervision.md) — do NOT report as unsupervised; auto-merge does not trigger

## lucos_configy

- [Null serialisation for optional fields](configy_null_fields.md) — use `dict.get(key) or default`, not `dict.get(key, default)`; configy sends explicit `null` for absent optional fields

## PR Process

- [Fresh review request after new commits](feedback_pr_new_commits.md) — pushing to an open PR requires a fresh SendMessage review request, not just a heads-up
- [Reporting PR completion: unsupervised vs non-unsupervised repos](feedback_pr_completion_reporting.md) — use different language depending on repo type
- [Check existing issues before filing](feedback_check_existing_issues.md) — search open issues first; other agents may have already filed the same finding
- [Grep for old name before renaming](feedback_rename_grep.md) — always `grep -r "old_name" .` before committing a rename; missed reference caused crash-loop + outage (lucos_arachne #267/#280)
- [Verify Dockerfile COPY when adding new files](feedback_dockerfile_copy.md) — check Dockerfile covers new dirs; `COPY *.py .` silently missed `ontologies/` dir (lucos_arachne #267/#282)

## lucos_eolas

- [Migrations: always use ./update.sh](feedback_lucos_eolas_migrations.md) — never run makemigrations directly; script handles Docker build, migration gen, makemessages, and locale sync in one step

## lucos_arachne ingestor

- **Entry**: `ingestor/ingest.py`. Tests: `python3 -m pytest` in `ingestor/`. All 117 pass.
- **Triplestore helpers**: `ingestor/triplestore.py`. `rdflib` already in Pipfile.
- **Skolemisation**: `ingestor/skolemise.py`. Blank nodes → `urn:lucos:skolem:<sha256>` (tree-shaped hash, cycle detection → UUID fallback).
- **Diff path** (PR #439, Option 2): `diff_graph_in_triplestore()` returns SPARQL Update fragment. Migration case (old graph has bnodes) uses `DELETE WHERE + INSERT DATA`. Phase 1 collects all live-source fragments, executes as one SPARQL Update. Ontologies keep `replace_graph_in_triplestore`.
- **loc_mads.rdf** doesn't parse with rdflib (invalid RDF/XML) — don't apply diff path to ontologies.
- **`COPY *.py .`** in Dockerfile covers all new `.py` files in `ingestor/`.

## lucos_media_manager

- **Language**: Java (requires Java 25 / Maven). Tests run in Docker: `docker run --rm -v $PWD:/app -w /app maven:3-eclipse-temurin-26-alpine mvn clean test`.
- **MediaApi**: `fetch()` (GET), `patch()` (PATCH with JSON body).
- **Tag write path**: `PATCH /v3/tracks/{trackid}` with body `{"tags": {"lastSuccessfulPlay": [{"name": "..."}]}}`. NOT `/v3/tracks/{trackid}/tags` (that returns 404).
- **Track.recordTag(tagName)**: best-effort — logs errors, never throws. Returns silently if `trackid` is null.
- **PlaylistTest**: use `new HashMap<>(Map.of(...))` not `Map.of()` for Track metadata — Track constructor calls `metadata.put()` which fails on immutable maps.

## lucos_media_weightings

- **Tests**: `cd src && python3 test_logic.py`. All tests in one file — add cases to the `testcases` list.
- **Tag format**: v3 tags are `{tagName: [{name: value}]}`. Use `getTagValue(tags, key)` to read.
- **Recency logic**: `lastSuccessfulPlay` tag → ÷50 if <1 day, ÷10 if <7 days. Bypassed if `about`/`mentions` matches `currentItems`. Follows same timezone-normalisation pattern as `added` tag.

## Shell Scripts over SSH — Binary Detection

**Use `test -x /usr/sbin/tool || test -x /sbin/tool` not `command -v tool`** when checking if a binary exists on a remote host via SSH. `command -v` looks up `$PATH`, and `/usr/sbin` isn't in regular users' PATH on most systems — so `command -v usermod` returns 1 even on hosts where `sudo usermod` works fine. `test -x` on known paths has no PATH dependency and works in busybox ash. Caught in lucos_backups#269.

## arachne MCP

- [find_entities returns rdfs:label not skos:prefLabel](feedback_arachne_find_entities_labels.md) — use get_entity(uri) to get the canonical skos:prefLabel; find_entities returns alternate names sorted alphabetically
