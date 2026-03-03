# SRE Agent Memory

See topic files for details. Key patterns confirmed in operation:

## lucos_photos — Known Issues & Patterns
- `pg_isready` fix tracked in open issue #39 (split from #25, which is now closed). Engine-at-import-time tracked in open issue #40.
- `/_info` checks/metrics both empty — not yet operationally useful. Issues #10 and #11 still open.
- Worker not yet implemented — Loganne event delivery mechanism unresolved (issue #24 still open).
- Database indexes added via Alembic migration (issue #20 closed/completed by lucos-developer).
- Qdrant replaced by pgvector (#29 completed) — Qdrant-specific volume/config concerns are moot.
- `lucos_photos_postgres_data` volume classified as `considerable` (not `huge`) — lucas42 confirmed manually curated face/person data is re-doable with effort.

## Closed Issue Learnings
- Issue #9 (add env vars to worker proactively): closed `not_planned` — lucas42 preference is to add env vars only when a container actually needs them, not speculatively. Don't raise issues proposing env vars "in advance of future functionality".
- Issue #25 (database.py import-time engine): split into #39 and #40 per lucas42. SRE diagnosis of `pg_isready` startup thrash was confirmed correct. Both sub-issues now open and approved.

## Infrastructure Patterns
- `depends_on` only waits for container start, not service readiness — always use `pg_isready` or equivalent in entrypoints.
- Redis (`redis:7-alpine`) has persistence disabled by default — not suitable for durable queues without AOF/RDB config.
- `/_info` checks must never propagate exceptions as 500s — monitoring distinguishes 500 (API broken) from `ok:false` (dependency unhealthy).
- `lucos_monitoring` fetches `/_info` with a hard 1-second timeout. Health check timeouts inside `/_info` handlers must be well under 1 second (0.5s is a safe ceiling) or the whole endpoint times out and the service appears fully down.
- Docker Compose named volumes must appear in both `services.<name>.volumes` and top-level `volumes:` AND in `lucos_configy/config/volumes.yaml`.

## Issue Review Workflow
- When not commenting on an issue because another agent has already covered the SRE angles: add a +1 reaction to that agent's comment instead of doing nothing.
- Reaction API: `repos/lucas42/{repo}/issues/comments/{comment_id}/reactions --method POST` with payload `{"content": "+1"}`.

## GitHub API
- Always use `--app lucos-site-reliability` with `gh-as-agent`.
- Pass body text inline using `-f body="..."` — no need to write payload files.
- For issue comments: `repos/lucas42/{repo}/issues/{n}/comments --method POST`.
- To edit an existing comment: `repos/lucas42/{repo}/issues/comments/{comment_id} --method PATCH`.
- Can't use Write tool on a path that already has content without reading first — use Bash `cat >` heredoc instead.
- IMPORTANT: When using `-f body="..."` with backtick code spans, the shell will try to execute the backtick content as a subcommand. Always use a heredoc via `BODY=$(cat <<'ENDBODY' ... ENDBODY)` and pass as `--field body="$BODY"` to safely include backtick-formatted code in issue/comment bodies.
