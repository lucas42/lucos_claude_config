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
- **Worker**: Entry point `worker/app/main.py`. RQ worker on queue `"photos"`. Tests in `worker/tests/`. Run with `cd worker && python3 -m pytest`.
- **Shared**: `shared/lucos_photos_common/` — `database.py` (SQLAlchemy engine), `models.py` (ORM models), `jobs.py` (RQ job handlers: `process_photo`, `reprocess_photo`).
- **Job handlers in shared**: Both API (enqueue) and worker (execute) import from `lucos_photos_common.jobs`. Avoids string-based module path references.
- **API tests use SQLite in-memory** via `conftest.py`; Redis unavailability is non-fatal — `enqueue_process_photo` catches exceptions.
- **Worker tests patch `lucos_photos_common.jobs.SessionLocal`** directly to inject SQLite sessions.
- **CI**: Two test jobs — `test-api` and `test-worker` — run in parallel with `lucos/build-amd64`.
- `python3` is the binary (not `python`) in the local shell environment.
- **Upload auth**: `Authorization: key <API_KEY>` header; `CLIENT_KEYS` env var is semicolon-separated `name=value` pairs.
- **Deduplication**: Server uses SHA256 — returns 200 if duplicate, 201 if new.

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
- **Local SDK**: Only android-34 + build-tools 34.0.0 installed at `/opt/android-sdk`. SDK dir is read-only — cannot install SDK 35/36 locally.
- **Conscrypt aarch64 issue**: Robolectric tests fail locally with `UnsatisfiedLinkError: no conscrypt_openjdk_jni-linux-aarch_64` because `conscrypt-openjdk-uber:2.5.2` (Robolectric's dep) has no aarch64 native lib. CI (x86_64) is unaffected.
- **WorkManager + Robolectric tests**: Use `@Config(sdk = [34], application = Application::class)` to prevent Robolectric from instantiating `PhotoBackupApplication`, whose `onCreate()` initialises WorkManager's static singleton. WorkManager's singleton interacts badly with Robolectric's per-test lifecycle. `TestListenableWorkerBuilder` bypasses WorkManager entirely — no WorkManager init is needed in tests.

## lucos_monitoring

- **Language**: Erlang, built with rebar3. Key logic in `src/fetcher.erl`.
- **Tests**: EUnit tests in `fetcher.erl` inside `-ifdef(TEST)` block. No Erlang locally — tests run in CI only.
- **CircleCI check**: Uses v2 API — fetches pipeline via `/project/{slug}/pipeline?branch=main`, then workflows via `/pipeline/{id}/workflow`. Auth via `Circle-Token` header (not query param like v1.1).
- **Workflow statuses**: `failed` → red, `success`/`running`/`on_hold` → green.
- **`checkWorkflowStatuses/4`**: Pure function, fully unit-testable without HTTP mocks.

## Docker Naming Convention (always check this)

- `container_name` must be `lucos_<project>_<role>` — e.g. `lucos_repos_app`, `lucos_photos_api`
- `image` must be `lucas42/lucos_<project>_<role>` — e.g. `lucas42/lucos_repos_app`
- Single-container services typically use `_app` as the role
- Missing the role suffix is a recurring review comment — check docker-compose.yml before opening any PR

## GitHub Repo Creation

- Apps don't have permission to create repos via GitHub API — use `gh repo create` (regular CLI).
- When creating a new repo for a PR workflow, push an empty initial commit to `main` first, then create the feature branch from it and open PR. (Orphan branches for main cause "no history in common" errors.)
