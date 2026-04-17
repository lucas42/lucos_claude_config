# SRE Agent Memory

## Production Host Directory Structure

No persistent per-service directories on production hosts. Docker Compose files deploy transiently to `/home/circleci/project` during CI only. Use container names directly:

```bash
docker logs lucos_monitoring   # correct
docker restart lucos_monitoring
# Wrong: cd /home/docker/lucos_time && docker compose stop
```

Container names match the service name in `docker-compose.yml`.

## Standing Rules

**Read the full function before editing any part of it.** Partial edits risk removing assignments used further down (caused regression in lucos_backups PR #62).

**Test Locally Before Pushing**: Docker available locally. Always build and run container locally before opening a PR. Pushed untested fixes to production → 3-PR crash-loop incident 2026-03-14.

## lucos_deploy_orb — Known Patterns
- Issue #21 (port-contention-during-deploy): open. `docker compose up --wait` fails when new container can't bind host port held by old container.
- Issue #42 (open): "Notify Loganne" step fails CI on transient loganne outages — should be non-blocking.
- Issue #43 (open): root cause tracking for 2026-03-20 stale CI failures.
- Issue #71 (open): `depends_on` with `condition: service_healthy` leaves containers stuck in "Created" state when `--wait-timeout` expires. Distinct from #21 (host-networked port contention). Affects bridge-networked services like lucos_eolas, lucos_contacts.
- Issue #84 (open, P2): `Docker Tag & Push (Latest)` step tries to push upstream images (postgres, pgvector, owntracks/recorder) that weren't locally built. Affects repos with non-built services in docker-compose. Blocks deploys for lucos_eolas, lucos_contacts, lucos_photos, lucos_locations.
- **calc-version runs on ALL branches** (not just main) — `build-amd64` has no branch filter. Version tags get pushed from branch builds. This caused a token burnout incident on 2026-04-16 when ~57 simultaneous branch builds hit GitHub's abuse detection. Fix needed: check `CIRCLE_BRANCH == main` before pushing tags.
- **Estate-wide rollout + shared token = abuse detection risk**: GitHub flags tokens used for ~50+ simultaneous git push operations from distributed CI runners. Symptom: "Invalid username or token" error. Cooldown period unknown. Stagger estate-wide CI-triggering rollouts or use per-repo tokens.
- **CircleCI re-run vs new pipeline**: `rerun from_failed` uses the ORIGINAL pipeline config (including orb version resolved at creation). If the orb has changed, you need to trigger a NEW pipeline via `POST /api/v2/project/.../pipeline` with `{"branch": "main"}` to pick up the new version.
- **Docker Hub rate limit**: Triggering ~86 concurrent builds overwhelms Docker Hub pull limits. Free/basic accounts get 200 pulls/6hrs. Stagger builds or accept transient failures.
- **`lucos-ci` GitHub App (as of 2026-04-16)**: Replaced the old `GITHUB_TOKEN` PAT for CI git push + release creation. Uses `generate-github-token` orb command. Must be granted access to all repos individually.
- **PR #109 (merged 2026-04-17) bug — mirror redirect too broad**: The GHCR mirror `--build-context` injection in `publish-docker.yml`/`publish-docker-multiplatform.yml` rewrites EVERY non-scratch, non-stage-alias `FROM` image to `ghcr.io/lucas42/mirror/<img>`. This hits non-upstream images that shouldn't be mirrored: (a) our own `lucas42/*` images (e.g. `lucas42/lucos_navbar:2.1.52` → 403 on `ghcr.io/lucas42/mirror/lucas42/lucos_navbar`), (b) images from other registries like `gcr.io/distroless/*`, (c) Dependabot-upgraded versions not yet mirrored. Needs follow-up: scope the redirect to `docker.io/library/*` only, or allowlist against a curated list.
- **"Tagged-but-not-pushed" cascading failure**: `calc-version` pushes the git tag BEFORE the Docker image is pushed. If the Docker build fails (e.g. rate limit), the tag is left stranded. On re-trigger, `git describe --exact-match --tags HEAD` matches → `circleci-agent step halt exit 0` → workflow continues past build → deploy-avalon pulls a non-existent image → "manifest unknown". Affected 2026-04-17: lucos_creds v1.0.9, lucos_contacts_web v1.0.9, lucos_locations_otfrontend v1.0.6, lucos_media_metadata_manager v1.0.12, lucos_media_seinn (check), lucos_repos_app v1.0.8. Fix options: (a) push tag AFTER image push succeeds, (b) halt the entire workflow (not just the job) when already-tagged, (c) detect missing image and rebuild.
- Issue #103 (open): `scp … /dev/stdout >> "$BASH_ENV"` **truncates** `$BASH_ENV` — does NOT append. `/dev/stdout` is a symlink to `/proc/self/fd/1`; opening that path re-opens the underlying file with `O_WRONLY|O_CREAT|O_TRUNC` (scp-via-SFTP's default open flags), wiping whatever earlier steps wrote. `>>` on the outer shell is useless against a command that opens its destination as a path. Grep-filter workaround (`scp … /dev/stdout | grep …`) fails too: pipe fd is non-seekable and SFTP's positioned writes silently produce nothing. Fix: use `ssh remote cat file >> "$BASH_ENV"` instead — ssh writes to a real stdout stream. General rule: never use `/dev/stdout` as a command's destination path when you want shell redirection to behave; use `-` or a real stdout-emitting command.

## lucos_photos — Known Issues & Patterns
- `pg_isready` fix tracked in open issue #39. Engine-at-import-time in open issue #40.
- `/_info` checks/metrics both empty — issues #10 and #11 still open.
- Worker not implemented — Loganne event delivery unresolved (issue #24 still open).
- Issue #202 (Loganne 400 on photoProcessed events): open, P3. Non-fatal but every process_photo job emits it.
- Issue #213 (Contact display names): `sweep_contact_display_names` builds double-slash URLs (trailing slash on `LUCOS_CONTACTS_URL` + leading slash on path). Fix: strip trailing slash.
- **reprocess_photo idempotency trap**: `process_photo` short-circuits if original file AND thumbnail both exist. To force regeneration, delete thumbnails from `/data/photos/derivatives/` first (named `{sha256hash}_thumb.jpg`).

## lucos_repos — Convention Checks
- Docker healthcheck convention (#59, closed 2026-03-07): every service with `build:` in docker-compose must have `healthcheck:`.
- YAML parse bug (#80, closed): `yaml.v3` can't unmarshal `workflows.version: 2` into struct — fixed in PR #81. Incident report at lucos/pull/44.
- Audit sweep skips archived repos; treats 410 (issues disabled) as soft failure (#90, closed).
- Rate limit bottleneck: GitHub Search API (30 req/min). `EnsureIssueExists` replaced with Issues List API (#67), backoff added (#68), success reporting fixed (#69).
- **last-audit-completed alert**: trigger `POST https://repos.l42.eu/api/sweep` when alert fires. Takes 5-15min. `/api/rerun` does NOT satisfy the monitoring check — use `/api/sweep`.
- Issue #285: 403 on public repos during audit = transient secondary rate limit, NOT permission error. `handleRateLimitError` must be wired into convention checks, not just `fetchReposPage`.

## lucos_arachne — Known Issues & Patterns
- Issue #319 (closed 2026-04-10): schedule-tracker notification timeout fixed by PR #320 (5s → 30s). **Do NOT confuse with the separate Typesense timeout.**
- Issue #327 (open, P2): `connection_timeout_seconds: 2` in `searchindex.py:287` causes tracks bulk import (~18K docs) to timeout. Items upsert succeeds, tracks times out. Fix: increase to 30s.
- Issue #250 (open): ingestor can't fetch contacts data — `contacts.l42.eu/people/all` requires auth.
- Issue #116 (P3): ingestor makes blocking bulk fetch on container start (~17s).
- **Do NOT recommend internal Docker URLs** between services — creates tight coupling. Use external HTTPS URLs.
- Ingestor runs on cron: `15 04 * * *` UTC (Dockerfile). Initial ingest on container start via `startup.sh`.
- Base image: `lucas42/lucos_scheduled_scripts:2.0.2`.

## lucos_creds — Known Issues
- Issue #199 (open, priority:low): SSH resolution to `lucos-creds` still failing from `lucos_creds_ui` despite `hostname: lucos-creds`. Docker DNS may not register hostname as alias on all network configs.
- Issue #152 (closed 2026-04-10): circular self-deploy dependency fixed — creds no longer needs itself to deploy.
- Issue #257 (open, P3): **Residual SSH disruption** — creds SSH service (port 2202) briefly unavailable during redeployment waves, causing other services' CI to fail at `Populate known_hosts`. Self-heals. Distinct from #152.

## Monitoring API Structure

**`/api/status` response**: `systems` is a **dict keyed by URL/name** (not a list). `checks` within each system is also a **dict keyed by check name** (not a list). Check for failures with `check.get('ok') == False` (not just falsy — missing `ok` means passing). Correct pattern:

```python
data = json.load(...)
for url, s in data['systems'].items():
    for cname, c in s.get('checks', {}).items():
        if c.get('ok') == False:
            print(url, cname, c.get('value',''))
```

## lucos_monitoring — Known Issues
- Issue #148 (open, priority:low, owner:lucos-site-reliability): CircleCI check errors on repos with 0 active pipelines (`.github` has no CI config; `vue-leaflet-antimeridian` has config but project not activated). Fix: return neutral/unknown when 0 pipelines instead of erroring.
- CircleCI check: v2 workflow-level API via #30/#32. Fix #48 (closed): check last 5 pipelines, flatten workflows, keepLatestWorkflowPerName to avoid race condition.
- **Erlang OTP ssl startup**: `ensure_all_started(inets)` does NOT start ssl. Use `application:ensure_all_started([ssl, inets])` — walks full dependency chain. Closed as #52/#54.
- lucos_arachne ingestor unhandled webhook types → 404, events dropped silently. Issue lucos_arachne#53.
- media-api.l42.eu (lucos_media_manager) `/_info` times out — appears `unknown` in monitoring. Issue #146 (P2).
- `LongPollControllerV3Test` flaky — issue #79 (priority:high). Related `ConcurrentModificationException` in Playlist.hashCode() — `LinkedList` not thread-safe. Issue #151 (P2).
- Issue #41 (Emit Loganne events on health transitions): agent-approved, priority:medium.
- Issue #50 (server.erl eaddrinuse retry): open, PR #51 in review.
- Issue #132 (suppression bypassed on fetch-info failures): priority:high. Root cause: `fetcher_info.erl` returns `System = "unknown"` on unreachable `/_info`; suppression lookup uses this and always misses. Fix: use configy `id` field as authoritative identifier.

## lucos_locations — Known Issues
- Issue #9 (P3): mosquitto "protocol error" from TLS healthcheck. PR #15 approved (MQTT handshake in fallback), awaiting human merge.
- Issue #10 (P3): otfrontend nginx logs `connect() failed (111)` to `[::1]:8080/_info` on every monitoring poll. External `/_info` returns 200 (static fallback) — potentially false health signal.

## tfluke — Known Issues
- Stale TfL API IDs: `london-overground` line ID, empty vehicle ID to arrivals, stop ID `490007268X`. Issue #227 (P3).

## lucos_media_seinn — Known Issues
- `ValidationError is not defined` in `src/server/v3.js:19` firing on every request. Issue #176 (P2).

## lucos_docker_health — Known Issues
- Issue #58 (P3): Docker socket `context deadline exceeded` flood (80+ warnings/2min) during deploy waves — log noise only, container recovers.

## lucos_comhra — Known Issues
- Issue #3: closed — `restart: always` added to llm and agent services.

## lucos_media_metadata_manager — Known Issues (media-metadata.l42.eu)
- Issue #58 (P3): PHP warnings for missing isset() on optional POST fields (updatetrack.php, bulkupdatetracks.php:32).
- Issue #149 (closed): healthcheck was calling `GET /v3/tracks` (46KB, 560ms) — exceeded 0.5s timeout. Fix: `GET /v3/tracks?limit=1`. **Pattern**: `/_info` healthchecks must never call large-payload endpoints.
- **2026-04-11 incident**: PR #208's server-side redirect to strip `?token=` from URLs triggered a redirect loop. Root cause: PHP `setcookie()` called without `path=` option (original code, pre-2026-04-08) defaults to the request URI directory — so cookies set at `/tracks/21842` get `path=/tracks/`. The new `path=/` cookie couldn't overwrite it. Fixed by PR #212: client-side `replaceState` + expiry headers for legacy path-scoped cookies.
- **PHP cookie path gotcha**: `setcookie()` without an explicit `path` option creates a cookie scoped to the request URI's directory, not `/`. Always specify `'path' => '/'` explicitly.
- **Auth monitoring blind spot**: `/_info` doesn't require auth, so authentication failures are invisible to monitoring. Issue #215 raised then closed not_planned — lucas42's view: auth.l42.eu reachability is already monitored, and per-service auth health checking deferred until there's active auth service work.

## lucos_media_manager — Known Issues (ceol.l42.eu)
- Issue #215 (open, priority:low): unhandled `java.util.NoSuchElementException` from scanner bots sending non-standard HTTP methods (STATS, etc). Noisy in logs but non-fatal.

## lucos_arachne — Known Issues
- **Incident 2026-04-08 (outage 1)**: `apt-get install` change dropped `wget` from Dockerfile while healthcheck still used it. Fix: PR #278 (use `curl`). **Always verify healthcheck tools aren't dropped when modifying Dockerfile apt lines.**
- **Incident 2026-04-08 (outage 2)**: rename `systems_to_graphs` → `live_systems` in `triplestore.py` — updated `ingest.py` but not `server.py`. Ingestor crash-looped. Fix: PR #280 (3-line rename). **Grep entire repo before renaming shared identifiers.**
- Issue #116 (P3): ingestor makes blocking bulk fetch on container start (~17s). Open.
- Issue #250 (open): ingestor can't fetch contacts data — `contacts.l42.eu/people/all` requires auth.
- Issue #319 (closed 2026-04-10): schedule-tracker notification timeout — fixed by PR #320 (bumped client to 1.0.21, 30s timeout). Superseded by #327 (Typesense timeout).
- **Triplestore 400**: multi-word language tags (e.g. "Scottish Gaelic") cause Fuseki 400 — space in IRI from `mapPredicate` without URL-encoding. Fix: `url.PathEscape(value)`. Issue #104.
- Always verify PR numbers from git log — commit messages don't include them. Look up via `gh api repos/lucas42/{repo}/commits/{sha}/pulls`.

## lucos_backups — Known Issues
- lucos_backups#57 / PR #56: PyPI clients call `sys.exit()` at import if `SYSTEM` env var missing. **Always audit import-time env var requirements when switching to PyPI clients.**
- Before raising issue during ops checks, search recently closed issues — the alert being red doesn't guarantee no issue exists.
- Issue #157 (closed): SSH command 3s timeout too tight during heavy deploy waves — was about avalon timeouts, self-healing.
- Issue #159 (open, P2): IPv6 route from avalon to salvare broken — "Hop limit exceeded". salvare.s.l42.eu has AAAA only (no A record). Network-level problem, needs sysadmin investigation. `POST /refresh-tracking` won't help — underlying route is broken.

## lucos_contacts — Known Issues & Patterns
- Django `ALLOWED_HOSTS` must include `127.0.0.1` for IP-based Docker healthchecks (`wget http://127.0.0.1:<port>/_info`). General pattern for all Django services.
- `schedule-tracker.l42.eu` check `lucos_contacts_googlesync_import` lags on recovery — self-heals without intervention.

## xwing — Host Facts
- Raspberry Pi 3, already 64-bit OS (Debian 13 trixie, aarch64). Confirmed 2026-03-16.
- Runs: lucos_router, lucos_media_import, lucos_media_linuxplayer, lucos_private, lucos_static_media. pici retired (repo archived 2026-03-17).
- `build-multiplatform` is now the standard for arm builds.

## Hostname → Repo Mappings (non-obvious)
- `media-api.l42.eu` → `lucos_media_metadata_api` (Go API)
- `media-metadata.l42.eu` → `lucos_media_metadata_manager` (PHP web UI)
- `ceol.l42.eu` → `lucos_media_manager` (player/queue UI)
- `am.l42.eu` → `lucos_time`
- Verify via `/_info` ci.circle field when in doubt.

## Infrastructure Patterns
- `depends_on` only waits for container start — always use `pg_isready` or equivalent in entrypoints.
- **`eaddrinuse` crash-loop**: new container fails immediately when old one holds the host port; `restart: always` keeps retrying. Symptom: exit code 0, restart count climbing, logs show `eaddrinuse`. Fix tracked in lucos_monitoring#50 and lucos_deploy_orb#21.
- **Missing PORT in deploy .env → silent no-host-port-binding**: container starts healthy internally but nginx router gets 502. Diagnose: `docker port <container>` returns empty. Fix: retrigger CI after creds corrected. Incident report: lucas42/lucos#53.
- **Healthcheck tool by base image**: `nginx:N` (Debian) has `curl` not `wget`. Alpine has `wget` not `curl`. `openjdk:N-jdk-slim` has NEITHER — install `curl` explicitly. Wrong tool → permanently unhealthy → dependents stuck in `Created`.
- **`docker compose up` does NOT stop removed services** — manually stop/remove containers for services deleted from docker-compose.
- When removing a service from docker-compose, also remove its `/_info` health check — stale checks alert after container disappears.
- Redis (`redis:7-alpine`) has persistence disabled by default — not suitable for durable queues without AOF/RDB config.
- `lucos_monitoring` fetches `/_info` with 1-second hard timeout. Health checks inside `/_info` must complete in <0.5s.
- Docker service names with underscores may fail DNS in Alpine (musl libc). Workaround: set `hostname:` with hyphenated name.
- **Branch protection `Analyze (actions)` vs `CodeQL` mismatch**: repos with no analyzable source code (static/config) run CodeQL "default setup" (github-advanced-security app) which reports check name `CodeQL` with conclusion `neutral`. `neutral` does NOT satisfy a required check. If branch protection requires `Analyze (actions)` (GitHub Actions, app_id 15368), Dependabot PRs will block permanently — that job never runs. Fix: remove `Analyze (actions)` from required status checks (lucos-system-administrator). Affects lucos_private, lucos_static_media as of 2026-04-10.
- Named Docker volumes must appear in `services.<name>.volumes`, top-level `volumes:`, AND `lucos_configy/config/volumes.yaml`.

## Ops Checks
- Tracking file: `ops-checks.md` — records last-run timestamps for monthly checks and per-container log review history.
- **7 checks** (not 6). Mandatory completion manifest table at end of each run. See `~/.claude/agents/sre-ops-checks.md`.
- CircleCI v2 API: extract token with `cut -d'"' -f2` to avoid surrounding quotes. Pipeline `state` is always "created" — check workflow state separately.
- `lucos-site-reliability` app does NOT have org-level repo list access — use sandbox list or per-repo API calls.
- **CI rerun ownership**: SRE diagnoses, asks lucos-system-administrator to trigger reruns (SRE token is read-only).

## _info Schema Compliance
- Spec doc: `~/.claude/references/info-endpoint-spec.md` and `lucos/docs/` (from lucos/issues/35, closed).
- CI status monthly check: `curl -s "https://circleci.com/api/v1.1/project/github/lucas42/{repo}?limit=3&filter=completed"` — no auth needed.
- CircleCI v2 rerun: `POST https://circleci.com/api/v2/workflow/{workflow_id}/rerun` with `-d '{"from_failed": true}'`.

## lucos_photos_android — Known Issues & Patterns
- Issue #28 (signing): Kotlin DSL variable shadowing — `keyPassword` in `SigningConfig.() -> Unit` lambda resolves to receiver member first. Prefix outer vals to avoid shadowing.
- Issue #31 (sync re-scans): fix was `WorkManager.enqueueUniqueWork()` with named key (was plain `enqueue`).
- Issue #30 (missing EXIF): photos genuinely lack DateTimeOriginal (screenshots, WhatsApp). Resolution: use file last-modified as fallback.

## GitHub App Limitations
- **`@dependabot` commands require push access** — no agent app has push access. Escalate `@dependabot rebase` etc. to lucas42 manually.

## Loganne Webhook Retry Operations
- Auto-retry fires ~30s after initial failure. Transient deploy-window failures self-heal.
- Bulk retry: `POST /events/retry-webhooks` with `Authorization: Bearer $KEY_LUCOS_LOGANNE`.
- Events API defaults to 7-day window. `webhook-error-count` metric covers all 10000 events in memory.
- Wait ~60s before manually intervening — auto-retry will likely clear it.

## GitHub API
- Always use `--app lucos-site-reliability` with `gh-as-agent`. Never `gh api` or `gh pr create`.
- Always use `<<'ENDBODY'` heredoc for `body` field — `-f body="..."` breaks newlines and backticks.
- Issue comments: `repos/lucas42/{repo}/issues/{n}/comments --method POST`.
- **Comment endpoint footgun**: POSTing to `repos/.../issues/comments/{comment_id}` OVERWRITES the existing comment's body (GitHub treats it as an update). To post a NEW comment, always use the issue-scoped endpoint `/issues/{n}/comments`. To edit, use `--method PATCH repos/.../issues/comments/{comment_id}`. Got burnt on lucos_deploy_orb#105 on 2026-04-17 — had to reconstruct a lost comment.
- The `lucos` repo has auto-merge — do not tell lucas42 to manually merge it.
- For `gh-as-agent` body with backtick code: use `BODY=$(cat <<'ENDBODY' ... ENDBODY)` and pass as `--field body="$BODY"`.
