# Architect Memory

## lucos_photos

- Reviewed Feb 2026 (commit c3be2c0). Summary issue: lucas42/lucos_photos#27
- Architecture: FastAPI API + Python worker + Postgres + Redis, 4 containers (Qdrant removed per ADR-0001)
- ADR-0001: Use pgvector instead of Qdrant for face embeddings (decided #23, implementation #29)
- ADRs live in `docs/adr/` with format `NNNN-short-description.md`
- Key open decision: job queue library (recommended RQ in #5 comment)
- Key open decision: how API learns about worker processing completion (#24)
- database.py has module-level engine creation -- fragile pattern (#25)
- No docker-compose healthchecks on any container -- reliability gap noted in #27
- PhotoPerson join table alongside Face table could create data consistency issues

## Cross-project patterns

- Module-level side effects in shared packages (database connections, env var reads) are a recurring fragility pattern. Watch for this in other projects.
- The lucos convention of hardcoding auth domain as `https://auth.l42.eu` is sometimes expressed as a compose env var (`LUCOS_AUTHENTICATION_URL`), which is confusing. Better to hardcode in application code.

## Infrastructure notes

- `lucos/build-amd64` CI orb builds and pushes Docker images; large images (>1GB) significantly impact build/deploy times
- `depends_on` in compose does not wait for service readiness, only container start. Projects with Postgres should have startup retry logic.
