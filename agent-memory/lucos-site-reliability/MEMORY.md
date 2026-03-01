# SRE Agent Memory

See topic files for details. Key patterns confirmed in operation:

## lucos_photos — Known Issues & Patterns
- `entrypoint.sh` has no `pg_isready` check before `alembic upgrade head` — will restart-thrash on startup. See issue #25.
- `/_info` checks/metrics both empty — not yet operationally useful. Issues #10 and #11 track fixes.
- Redis volume declared in `volumes.yaml` but verify it's properly mounted with explicit named volume in docker-compose (CLAUDE.md notes this as a known gap).
- Worker not yet implemented — Loganne event delivery mechanism unresolved (issue #24).

## Infrastructure Patterns
- `depends_on` only waits for container start, not service readiness — always use `pg_isready` or equivalent in entrypoints.
- Redis (`redis:7-alpine`) has persistence disabled by default — not suitable for durable queues without AOF/RDB config.
- `/_info` checks must use short timeouts (1-2s) and never propagate exceptions as 500s — monitoring distinguishes 500 (API broken) from `ok:false` (dependency unhealthy).
- Docker Compose named volumes must appear in both `services.<name>.volumes` and top-level `volumes:` AND in `lucos_configy/config/volumes.yaml`.

## GitHub API
- Always use `--app lucos-site-reliability` with `gh-as-agent`.
- Write payloads to file first (backtick safety), pass via `--input`.
- For issue comments: `repos/lucas42/{repo}/issues/{n}/comments --method POST`.
- Can't use Write tool on a path that already has content without reading first — use Bash `cat >` heredoc instead.
