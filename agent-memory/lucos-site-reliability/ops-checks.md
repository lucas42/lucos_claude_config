# Ops Checks Tracking

Tracks when each periodic ops check was last run, and per-container log review history.

## Periodic Checks

Format: `check_name: YYYY-MM-DD`

ci-status: 2026-03-05
info-quality: 2026-03-05
external-deps: 2026-03-05

## Container Log Review

Tracks the last-reviewed date for each container. Use `--since <last-reviewed-timestamp>` when SSHing to review logs.

Format: `container_name: YYYY-MM-DD`

lucos_photos_api: 2026-03-05
lucos_photos_worker: 2026-03-05
lucos_photos_qdrant: 2026-03-05
lucos_comhra_agent: 2026-03-05
loganne: 2026-03-05
