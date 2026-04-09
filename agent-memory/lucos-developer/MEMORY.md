# lucos-developer Memory

## lucos_creds

- **Server**: Go SSH/SFTP server in `server/src/`. Tests run with `/usr/local/go/bin/go test ./src`.
- **UI**: Node/Express in `ui/src/index.js`, EJS views in `ui/src/views/`. No UI tests.
- **SSH command syntax**: `system/env/KEY=value` (set), `system/env/KEY=` (delete simple), `client/env => server/env` (create linked), `rm client/env => server` (delete linked), `ls` / `ls system/env` / `ls system/env/KEY` (read).
- **CI**: CircleCI runs Go tests in parallel with Docker build. Config in `.circleci/config.yml`.
- **`/usr/local/go/bin/go`** is the Go binary path (not on PATH in bash tool sessions).
- Linked credential DB schema: UNIQUE on (clientsystem, clientenvironment, serversystem) — serverenvironment not part of the unique key.

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

- **Repo**: `https://github.com/lucas42/lucos_photos_android` (created 2026-03-04)
- **Language**: Kotlin, minSdk 26, targetSdk 36, compileSdk 36
- **Build**: Gradle 9.4.0 wrapper, AGP 9.1.0. CI uses `cimg/android:2025.01` (x86_64).
- **AGP 9.x migration**: `org.jetbrains.kotlin.android` plugin is **rejected** by AGP 9.0+ (hard error, not warning). Remove from both `build.gradle.kts` files and `libs.versions.toml`. Replace `kotlinOptions { jvmTarget }` with `kotlin { jvmToolchain(17) }`.
- **CodeQL for Android takes 15-30 min** — the `updated_at` field in GitHub API stays frozen at creation time during the run; this is a GitHub API quirk, not a stall. Do not flag slow CodeQL runs to lucos-site-reliability.
- **Key files**: `app/src/main/kotlin/eu/l42/lucos_photos_android/`
  - `PhotoSyncWorker.kt` — WorkManager CoroutineWorker, MediaStore query, incremental timestamp sync
  - `PhotoUploader.kt` — OkHttp multipart upload, retryable/non-retryable failure classification
  - `SyncPreferences.kt` — SharedPreferences wrapper for lastSyncTimestampMs
  - `Config.kt` — hardcoded SERVER_URL and API_KEY (placeholder in v1)
  - `PhotoSyncWorkerFactory.kt` — custom WorkerFactory for DI
  - `PhotoBackupApplication.kt` — manually inits WorkManager (auto-init disabled in manifest)
- **Tests**: Robolectric (sdk=34) for worker tests, plain JUnit + mockk for uploader tests
- **Local SDK**: Android SDK 36 + build-tools installed at `/opt/android-sdk` (as of 2026-03-10). Tests are configured with `@Config(sdk = [34])` so Robolectric still uses SDK 34 for test execution.
- **Conscrypt aarch64 issue**: Robolectric tests (`PhotoSyncWorkerTest`) fail locally with `UnsatisfiedLinkError: no conscrypt_openjdk_jni-linux-aarch_64` because `conscrypt-openjdk-uber:2.5.2` (Robolectric's dep) has no aarch64 native lib. Installing SDK 36 does NOT fix this — it is a Robolectric/Conscrypt issue unrelated to the Android SDK version. CI (x86_64) is unaffected. `PhotoUploaderTest` (plain JUnit + mockk, no Robolectric) passes locally fine.
- **WorkManager + Robolectric tests**: Use `@Config(sdk = [34], application = Application::class)` to prevent Robolectric from instantiating `PhotoBackupApplication`, whose `onCreate()` initialises WorkManager's static singleton. WorkManager's singleton interacts badly with Robolectric's per-test lifecycle. `TestListenableWorkerBuilder` bypasses WorkManager entirely — no WorkManager init is needed in tests.
- **Robolectric MediaStore seeding**: `ContentResolver.insert()` on MediaStore URIs returns a URI but stores nothing (no real MediaProvider registered). Use `RoboCursor` + `ShadowContentResolver.setCursor(uri, cursor)` to pre-set query results, plus `registerInputStream()` for `openInputStream()`. Do NOT rely on insert/query round-tripping.
- **`UploadResult` sealed class**: `Success` (201), `AlreadyUploaded` (200), `AuthFailure(message, errorKey)` (401/403), `Failure(message, retryable, errorKey)` (other errors). `errorKey` is the HTTP status code string or `"network"` / `"stream"` / `"exception"`.
- **`TelemetryReporter.reportSync` signature**: `durationMs`, `itemsFound`, `photosFound`, `videosFound`, `photosSynced`, `alreadyUploaded`, `errors`, `errorBreakdown: Map<String, Int>`, `relativePathSample`, `tiktokFiltered=0`, `tiktokSignalBreakdown=emptyMap()`, `succeeded`. Omits `error_breakdown` and `tiktok_signal_breakdown` from JSON when empty.
- **TikTok filtering (Android 11+)**: `TikTokClassifier` in `TikTokClassifier.kt` — multi-signal scoring (threshold 60). Videos only; photos are not filtered. `seedMediaStoreWithVideo` must include WIDTH, HEIGHT, DURATION columns — `RoboCursor.java:41` IllegalArgumentException if any projection column is missing from the cursor.
- **Run `PhotoUploaderTest`, `TelemetryReporterTest`, `TikTokClassifierTest` locally** (plain JUnit/mockk, no Robolectric). Run as: `./gradlew :app:testDebugUnitTest --tests "eu.l42.lucos_photos_android.PhotoUploaderTest" --tests "eu.l42.lucos_photos_android.TelemetryReporterTest" --tests "eu.l42.lucos_photos_android.TikTokClassifierTest"`

## lucos_monitoring

- **Language**: Erlang, built with rebar3. Key logic in `src/fetcher.erl`.
- **Tests**: EUnit tests in each `.erl` file inside `-ifdef(TEST)` block. No Erlang locally — tests run in CI only.
- **CircleCI check**: Uses v2 API — fetches pipeline via `/project/{slug}/pipeline?branch=main`, then workflows via `/pipeline/{id}/workflow`. Auth via `Circle-Token` header (not query param like v1.1).
- **Workflow statuses**: `failed` → red, `success`/`running`/`on_hold` → green.
- **`checkWorkflowStatuses/4`**: Pure function, fully unit-testable without HTTP mocks.
- **Erlang string pitfalls**: `re:replace(..., {return, list})` returns an iolist (nested list), not a flat string. Always wrap with `lists:flatten/1` before using `++`. Similarly, `lists:join/2` returns an iolist — use `string:join/2` instead when a flat list is needed for `++` concatenation.
- **`httpc` status matching**: status code is an integer (e.g. `200`), not a partial pattern. Use a guard: `when StatusCode >= 200, StatusCode < 300` — not `{_, 2, _}`.

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

## Java Mockito — Phase-dependent auth mocks

When refactoring auth checks in Java controllers, ALL mock-creating helpers must be updated:
- `compareRequestResponse` — mock helper, needs auth setup
- `checkNotAllowed` — separate mock helper, easy to miss
If switching from `hasAuthorizationHeader() && !isAuthorised()` (Phase 1) to `!isAuthorised()` (Phase 3), add `when(request.isAuthorised()).thenReturn(true)` to BOTH helpers.

## Never Merge PRs (recurring failure — critical)

**STOP. Do not call the merge endpoint.** `pr-review-loop.md` step 2 is explicit: "do not merge. Never call the merge API on any PR — merging is handled by auto-merge (GitHub) or the user, not agents." `unsupervisedAgentCode = YES` means auto-merge handles it — it does NOT mean I should merge. After approval: report back, done.

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

## PR Process

- [Fresh review request after new commits](feedback_pr_new_commits.md) — pushing to an open PR requires a fresh SendMessage review request, not just a heads-up
- [Reporting PR completion: unsupervised vs non-unsupervised repos](feedback_pr_completion_reporting.md) — use different language depending on repo type
- [Check existing issues before filing](feedback_check_existing_issues.md) — search open issues first; other agents may have already filed the same finding
- [Grep for old name before renaming](feedback_rename_grep.md) — always `grep -r "old_name" .` before committing a rename; missed reference caused crash-loop + outage (lucos_arachne #267/#280)
- [Verify Dockerfile COPY when adding new files](feedback_dockerfile_copy.md) — check Dockerfile covers new dirs; `COPY *.py .` silently missed `ontologies/` dir (lucos_arachne #267/#282)
