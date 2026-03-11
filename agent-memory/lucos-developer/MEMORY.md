# lucos-developer Memory

## lucos_creds

- **Server**: Go SSH/SFTP server in `server/src/`. Tests run with `/usr/local/go/bin/go test ./src`.
- **UI**: Node/Express in `ui/src/index.js`, EJS views in `ui/src/views/`. No UI tests.
- **SSH command syntax**: `system/env/KEY=value` (set), `system/env/KEY=` (delete simple), `client/env => server/env` (create linked), `rm client/env => server` (delete linked), `ls` / `ls system/env` / `ls system/env/KEY` (read).
- **CI**: CircleCI runs Go tests in parallel with Docker build. Config in `.circleci/config.yml`.
- **`/usr/local/go/bin/go`** is the Go binary path (not on PATH in bash tool sessions).
- Linked credential DB schema: UNIQUE on (clientsystem, clientenvironment, serversystem) — serverenvironment not part of the unique key.

## lucos_photos

- **API**: FastAPI in `api/app/main.py`. Tests in `api/tests/`. Run with `cd api && python3 -m pytest`.
- **Model JSON type**: Use SQLAlchemy `JSON` (not `JSONB`) in models — `JSONB` is Postgres-only and breaks SQLite in-memory tests.
- **Auth pattern for M2M endpoints**: use `verify_key` dependency (same as `POST /photos`). `verify_session` is for browser/cookie auth only.
- **Some tests hang** when run together — `test_main.py::TestUpload` calls `emit_loganne_event` which tries to connect to the real Loganne service. This is pre-existing; run `tests/test_telemetry.py` and `tests/test_photos.py` separately for fast feedback.
- **Worker**: Entry point `worker/app/main.py`. RQ worker on queue `"photos"`. Tests in `worker/tests/`. Run with `cd worker && python3 -m pytest`.
- **Shared**: `shared/lucos_photos_common/` — `database.py` (SQLAlchemy engine), `models.py` (ORM models), `jobs.py` (RQ job handlers: `process_photo`, `reprocess_photo`).
- **Job handlers in shared**: Both API (enqueue) and worker (execute) import from `lucos_photos_common.jobs`. Avoids string-based module path references.
- **API tests use SQLite in-memory** via `conftest.py`; Redis unavailability is non-fatal — `enqueue_process_photo` catches exceptions.
- **Worker tests patch `lucos_photos_common.jobs.SessionLocal`** directly to inject SQLite sessions.
- **CI**: Two test jobs — `test-api` and `test-worker` — run in parallel with `lucos/build-amd64`.
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
- **Build**: Gradle 8.11.1 wrapper, AGP 8.9.1. CI uses `cimg/android:2025.01` (x86_64).
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
- **`TelemetryReporter.reportSync` signature**: `durationMs`, `itemsFound`, `photosSynced`, `alreadyUploaded`, `errors`, `errorBreakdown: Map<String, Int>`, `succeeded`. JSON payload includes `error_breakdown` only when non-empty.
- **Run `PhotoUploaderTest` and `TelemetryReporterTest` locally** (plain JUnit/mockk, no Robolectric). Run as: `./gradlew :app:testDebugUnitTest --tests "eu.l42.lucos_photos_android.PhotoUploaderTest" --tests "eu.l42.lucos_photos_android.TelemetryReporterTest"`

## lucos_monitoring

- **Language**: Erlang, built with rebar3. Key logic in `src/fetcher.erl`.
- **Tests**: EUnit tests in `fetcher.erl` inside `-ifdef(TEST)` block. No Erlang locally — tests run in CI only.
- **CircleCI check**: Uses v2 API — fetches pipeline via `/project/{slug}/pipeline?branch=main`, then workflows via `/pipeline/{id}/workflow`. Auth via `Circle-Token` header (not query param like v1.1).
- **Workflow statuses**: `failed` → red, `success`/`running`/`on_hold` → green.
- **`checkWorkflowStatuses/4`**: Pure function, fully unit-testable without HTTP mocks.

## Docker Conventions

See `~/.claude/references/docker-conventions.md` for canonical Docker conventions (container naming, volumes, healthchecks). Missing the role suffix in container_name/image is a recurring review comment — check docker-compose.yml before opening any PR.

## GitHub Repo Creation

- Apps don't have permission to create repos via GitHub API — use `gh repo create` (regular CLI).
- When creating a new repo for a PR workflow, push an empty initial commit to `main` first, then create the feature branch from it and open PR. (Orphan branches for main cause "no history in common" errors.)
