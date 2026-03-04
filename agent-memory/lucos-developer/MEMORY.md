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
