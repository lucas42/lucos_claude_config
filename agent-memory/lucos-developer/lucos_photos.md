---
name: lucos-photos
description: API/worker structure, test patching locations, and implementation gotchas for lucos_photos
metadata:
  type: project
---

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
