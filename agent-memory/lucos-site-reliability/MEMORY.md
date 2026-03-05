# SRE Agent Memory

See topic files for details. Key patterns confirmed in operation:

## lucos_photos — Known Issues & Patterns
- `pg_isready` fix tracked in open issue #39 (split from #25, which is now closed). Engine-at-import-time tracked in open issue #40.
- `/_info` checks/metrics both empty — not yet operationally useful. Issues #10 and #11 still open.
- Worker not yet implemented — Loganne event delivery mechanism unresolved (issue #24 still open).
- Database indexes added via Alembic migration (issue #20 closed/completed by lucos-developer).
- Qdrant replaced by pgvector (#29 completed) BUT orphaned `lucos_photos_qdrant` container and `lucos_photos_qdrant_data` volume still exist on avalon. Tracked in open issue #76. Until cleaned up, backups monitoring will remain erroring.
- PostgreSQL collation version mismatch (2.41 vs 2.36) logged as WARNING on worker startup. P3 issue raised as #77.
- `lucos_photos_postgres_data` volume classified as `considerable` (not `huge`) — lucas42 confirmed manually curated face/person data is re-doable with effort.

## Closed Issue Learnings
- Issue #9 (add env vars to worker proactively): closed `not_planned` — lucas42 preference is to add env vars only when a container actually needs them, not speculatively. Don't raise issues proposing env vars "in advance of future functionality".
- Issue #25 (database.py import-time engine): split into #39 and #40 per lucas42. SRE diagnosis of `pg_isready` startup thrash was confirmed correct. Both sub-issues now open and approved.
- Issue #71 (ImportError on alembic/env.py after engine refactor): closed/resolved by PR #72. Incident was caused by a batched deployment of 6+ PRs after 13-hour CI break — batch deployments amplify blast radius. Lesson: when refactoring a public shared-module name, grep the entire repo (including `alembic/`, `conftest.py`, scaffolding) before merging.
- lucos/issues/33 (incident report convention): decided and closed. Convention is `docs/incidents/` directory in the `lucos` repo, one markdown file per incident. Implementation tracked in lucos/issues/34. Do not raise further issues about incident storage location — it's resolved.
- lucos_photos/issues/73 (branch protection on main): implemented by lucos-system-administrator. CI status checks (`ci/circleci: lucos/build-amd64`, `ci/circleci: test-api`, `ci/circleci: test-worker`) are now required before merge on lucos_photos main. Branch must also be up to date. `enforce_admins: false` as deliberate break-glass.

## lucos_monitoring — Known Issues
- CircleCI check (#30, open): uses `limit=1&filter=complete` which only fetches the single most recently completed CircleCI *job*. In a multi-job workflow, a fast-failing job (e.g. `build-amd64` failing in ~6s) is superseded within seconds by a passing test job completing later. The polling window to catch the failure can be as short as 3 seconds out of a 60-second poll interval. Fix options: (A) increase limit and check if any job in the batch failed, (B) use CircleCI v2 API for workflow-level results, (C) query `filter=failed&limit=1` and check recency.

## Infrastructure Patterns
- `depends_on` only waits for container start, not service readiness — always use `pg_isready` or equivalent in entrypoints.
- Redis (`redis:7-alpine`) has persistence disabled by default — not suitable for durable queues without AOF/RDB config.
- `/_info` checks must never propagate exceptions as 500s — monitoring distinguishes 500 (API broken) from `ok:false` (dependency unhealthy).
- `lucos_monitoring` fetches `/_info` with a hard 1-second timeout. Health check timeouts inside `/_info` handlers must be well under 1 second (0.5s is a safe ceiling) or the whole endpoint times out and the service appears fully down.
- Docker Compose named volumes must appear in both `services.<name>.volumes` and top-level `volumes:` AND in `lucos_configy/config/volumes.yaml`.

## Issue Review Workflow
- When not commenting on an issue because another agent has already covered the SRE angles: add a +1 reaction to that agent's comment instead of doing nothing.
- Reaction API: `repos/lucas42/{repo}/issues/comments/{comment_id}/reactions --method POST` with payload `{"content": "+1"}`.

## Ops Checks
- Tracking file: `ops-checks.md` — records last-run timestamps for monthly checks and per-container log review history. Always consult and update this file when running ops checks.

## /_info Schema Compliance
- Many older services missing `title` field — widespread gap, tracked in lucos/issues/35. Services missing `checks` too: lucos_scenes, lucos_eolas, lucos_configy, lucos_private, lukeblaney.co.uk, semweb.lukeblaney.co.uk.
- `lucos-site-reliability` app does NOT have org-level repo list access (`orgs/lucas42/repos` returns 404). Use locally-cloned sandboxes list or per-repo API calls instead.
- CI status monthly check: use `curl -s "https://circleci.com/api/v1.1/project/github/lucas42/{repo}?limit=3&filter=completed"` — no auth needed for public repos.

## GitHub API
- Always use `--app lucos-site-reliability` with `gh-as-agent`.
- Pass body text inline using `-f body="..."` — no need to write payload files.
- For issue comments: `repos/lucas42/{repo}/issues/{n}/comments --method POST`.
- To edit an existing comment: `repos/lucas42/{repo}/issues/comments/{comment_id} --method PATCH`.
- Can't use Write tool on a path that already has content without reading first — use Bash `cat >` heredoc instead.
- IMPORTANT: When using `-f body="..."` with backtick code spans, the shell will try to execute the backtick content as a subcommand. Always use a heredoc via `BODY=$(cat <<'ENDBODY' ... ENDBODY)` and pass as `--field body="$BODY"` to safely include backtick-formatted code in issue/comment bodies.
