---
name: topic-per-repo-known-issues
description: Per-repo known issues, quirks and open-ticket references across the lucos estate (photos, repos, arachne, creds, monitoring, locations, tfluke, seinn, docker_health, mma, media_manager, backups, contacts, photos_android, schedule_tracker) + host facts + hostname→repo mappings
metadata:
  type: reference
---

Consolidated from MEMORY.md 2026-07-03 (index compaction). Verify open/closed state via `gh-as-agent repos/lucas42/<repo>/issues/<N> --jq '.state'` before citing — these decay.

## lucos_schedule_tracker — API
- `DELETE /schedule/{system}` — idempotent, returns 204, no auth. Shipped PR #56 2026-04-18. Use to clean stale tracked jobs when a scheduled runner stops reporting.

## lucos_monitoring — Known Issues
- #148 (open, low, owner:SRE): CircleCI check errors on repos with 0 active pipelines (`.github` no CI config; `vue-leaflet-antimeridian` not activated). Fix: return neutral/unknown when 0 pipelines.
- #178 (open, P3): transient CircleCI workflow-fetch blip on the MOST RECENT pipeline lets a failed workflow from an OLDER pipeline win `keepLatestWorkflowPerName` → false `ok=false` for ~60s. `collectAllWorkflows` in `fetcher_circleci.erl` returns `[]` on HTTP error per pipeline; if most-recent fetch fails, old failure becomes "latest". Fix: bail to `ok=unknown` if most-recent pipeline's workflow fetch fails.
- CircleCI check: v2 workflow-level API via #30/#32. #48 (closed): check last 5 pipelines, flatten, keepLatestWorkflowPerName.
- Erlang OTP ssl startup: `ensure_all_started(inets)` does NOT start ssl; use `application:ensure_all_started([ssl, inets])`. #52/#54 closed.
- lucos_arachne ingestor unhandled webhook types → 404, events dropped silently (arachne#53).
- media-api.l42.eu (lucos_media_manager) `/_info` times out → `unknown` in monitoring. #146 (P2).
- `LongPollControllerV3Test` flaky — #79 (high). Related `ConcurrentModificationException` in Playlist.hashCode() (`LinkedList` not thread-safe) #151 (P2).
- #41 (Emit Loganne events on health transitions): agent-approved, medium.
- #50 (server.erl eaddrinuse retry): open, PR #51 in review.
- #132 (suppression bypassed on fetch-info failures, high): `fetcher_info.erl` returns `System="unknown"` on unreachable `/_info`; suppression lookup always misses. Fix: use configy `id` as authoritative identifier.

## lucos_photos — Known Issues
- `pg_isready` fix #39; engine-at-import-time #40 (open).
- `/_info` checks/metrics both empty — #10, #11 open.
- Worker not implemented — Loganne delivery unresolved #24.
- #202 (Loganne 400 on photoProcessed): open P3, non-fatal, every process_photo emits it.
- #213 (contact display names): `sweep_contact_display_names` builds double-slash URLs (trailing slash on `LUCOS_CONTACTS_ORIGIN` + leading slash on path). Fix: strip trailing slash.
- reprocess_photo idempotency trap: `process_photo` short-circuits if original + thumbnail both exist. Force regen by deleting `/data/photos/derivatives/{sha256}_thumb.jpg` first.

## lucos_repos — Convention Checks
- Docker healthcheck convention (#59 closed): every service with `build:` must have `healthcheck:`.
- YAML parse bug #80 (closed): `yaml.v3` can't unmarshal `workflows.version: 2` → fixed PR #81 (incident lucos/pull/44).
- Audit sweep skips archived repos; treats 410 (issues disabled) as soft failure (#90 closed).
- Rate-limit: GitHub Search API 30/min. `EnsureIssueExists`→Issues List API (#67), backoff (#68), success reporting (#69).
- **last-audit-completed alert**: trigger `POST https://repos.l42.eu/api/sweep` (5-15min). `/api/rerun` does NOT satisfy the check — use `/api/sweep`.
- #285: 403 on public repos during audit = transient secondary rate limit, NOT permission error. `handleRateLimitError` must wire into convention checks, not just `fetchReposPage`.

## lucos_arachne — Known Issues
- Incident 2026-04-08 (outage 1): `apt-get install` dropped `wget` while healthcheck used it. Fix PR #278 (use curl). Verify healthcheck tools aren't dropped when editing Dockerfile apt lines.
- Incident 2026-04-08 (outage 2): rename `systems_to_graphs`→`live_systems` in triplestore.py updated ingest.py not server.py → crash-loop. Fix PR #280. Grep entire repo before renaming shared identifiers.
- #327 (open P2): `connection_timeout_seconds: 2` in `searchindex.py:287` → tracks bulk import (~18K docs) times out; items upsert OK. Fix: 30s.
- #250 (open): ingestor can't fetch contacts data — `contacts.l42.eu/people/all` requires auth.
- #116 (P3): ingestor blocking bulk fetch on container start (~17s). Open.
- #319 (closed): schedule-tracker notification timeout fixed PR #320 (client 1.0.21, 30s). Superseded by #327. Do NOT confuse with Typesense timeout.
- Triplestore 400: multi-word language tags ("Scottish Gaelic") → Fuseki 400 (space in IRI from `mapPredicate` un-encoded). Fix `url.PathEscape(value)`. #104.
- Ingestor cron `15 04 * * *` UTC (Dockerfile); initial ingest on container start via startup.sh.
- Do NOT recommend internal Docker URLs between services (tight coupling). Use external HTTPS.
- Always verify PR numbers from git log via `gh api repos/lucas42/{repo}/commits/{sha}/pulls` (commit msgs omit them).
- 2026-04-20 TDB2 bloat incident (report `docs/incidents/2026-04-20-arachne-sparql-timeouts-tdb2-index-bloat.md`): PR #268 DROP GRAPH + re-INSERT grew TDB2 indexes <100MB→~93GB in 40 days vs 227K quads (tombstones never reclaimed without compaction). Resolution: online compaction + memory bump PR #387. Redesign #386. Follow-ups #388/#389/#386.
- **TDB2 online compaction**: `POST /$/compact/arachne?deleteOld=true` (admin auth). Zero downtime, ~1min, swaps Data-0001→Data-0002 atomically. Healthy on-disk ratio <10× live quad size (`SELECT (COUNT(*) AS ?n){?s ?p ?o}`); ≥100× = bloat.

## lucos_creds — Known Issues
- #199 (open, low): SSH resolution to `lucos-creds` failing from `lucos_creds_ui` despite `hostname: lucos-creds`. Docker DNS may not register alias on all net configs.
- #152 (closed): circular self-deploy dependency fixed.
- #257 (closed): creds SSH briefly unavailable during redeploy waves deemed addressed by `max_auto_reruns:5`+`auto_rerun_delay:30s` (150s). Scope gap: 2026-04-21 wave exceeded 150s → `getaddrinfo creds.l42.eu: Temporary failure` hard CI fail. If recurs: extend retry budget or sequence creds' deploy earlier. New issue, don't re-open #257.

## lucos_locations — Known Issues
- #9 (P3): mosquitto "protocol error" from TLS healthcheck. PR #15 approved (MQTT handshake in fallback), awaiting merge.
- #10 (P3): otfrontend nginx logs `connect() failed (111)` to `[::1]:8080/_info` every poll. External `/_info` returns 200 (static fallback) — potential false health signal.

## tfluke — Known Issues
- Stale TfL API IDs: `london-overground` line ID, empty vehicle ID to arrivals, stop ID `490007268X`. #227 (P3).

## lucos_media_seinn — Known Issues
- `ValidationError is not defined` in `src/server/v3.js:19` on every request. #176 (P2).

## lucos_docker_health — Known Issues
- #58 (P3): Docker socket `context deadline exceeded` flood (80+/2min) during deploy waves — log noise only, recovers.

## lucos_media_metadata_manager — Known Issues (media-metadata.l42.eu)
- #58 (P3): PHP warnings for missing isset() on optional POST fields (updatetrack.php, bulkupdatetracks.php:32).
- #149 (closed): healthcheck called `GET /v3/tracks` (46KB, 560ms) > 0.5s. Fix `?limit=1`. Pattern: `/_info` healthchecks must never call large-payload endpoints.
- 2026-04-11 incident: PR #208 server-side redirect to strip `?token=` → redirect loop. Root cause: PHP `setcookie()` without `path=` defaults to request-URI dir → cookie at `/tracks/21842` gets `path=/tracks/`; new `path=/` cookie couldn't overwrite. Fixed PR #212 (client-side replaceState + expiry headers).
- **PHP cookie path gotcha**: `setcookie()` without explicit `path` scopes to request-URI dir, not `/`. Always `'path'=>'/'`.
- Auth monitoring blind spot (lesson valid, updated 2026-06-29 post lucos_authentication decommission): `/_info` doesn't require auth → auth failures invisible to monitoring. #215 closed not_planned (lucas42: auth-service reachability already monitored at service level; per-service auth health deferred). Original example auth.l42.eu now → lucos_aithne/aithne.l42.eu.

## lucos_media_manager — Known Issues (ceol.l42.eu)
- #215 (open, low): unhandled `java.util.NoSuchElementException` from scanner bots sending non-standard HTTP methods (STATS etc). Noisy, non-fatal.

## lucos_backups — Known Issues
- #57/PR #56: PyPI clients call `sys.exit()` at import if `SYSTEM` env missing. Audit import-time env requirements when switching to PyPI clients.
- Before raising an issue during ops checks, search recently closed — red alert doesn't guarantee no issue exists.
- #157 (closed): SSH command 3s timeout too tight during heavy deploy waves (avalon timeouts, self-healing).
- #159 (closed via PR #160): IPv6 route flap avalon→salvare (salvare AAAA only, OVH route occasionally unreachable). Fix routes Fabric via xwing ProxyJump. **PR #160 incomplete — only covers `Host.__init__` primary connection, not raw ssh/scp in `copyFileTo`/`fileExistsRemotely` (host.py:77,82); those still go direct + fail on IPv6 flaps. Tracked #185 (open P2).** Recurrence symptom: schedule-tracker alerts `lucos_backups` with `ssh: connect to host salvare.s.l42.eu port 22: No route to host`; /_info all-OK (failure in cron run, not live service). Clears on next successful run (~03:25 UTC).

## lucos_contacts — Known Issues
- Django `ALLOWED_HOSTS` must include `127.0.0.1` for IP-based Docker healthchecks (`wget http://127.0.0.1:<port>/_info`). General Django pattern.
- `schedule-tracker.l42.eu` check `lucos_contacts_googlesync_import` lags on recovery — self-heals.

## lucos_photos_android — Known Issues
- #28 (signing): Kotlin DSL variable shadowing — `keyPassword` in `SigningConfig.()->Unit` resolves to receiver member first. Prefix outer vals.
- #31 (sync re-scans): fix was `WorkManager.enqueueUniqueWork()` named key (was plain enqueue).
- #30 (missing EXIF): photos genuinely lack DateTimeOriginal (screenshots, WhatsApp). Resolution: file last-modified fallback.

## xwing — Host Facts
- Raspberry Pi 3, 64-bit OS (Debian 13 trixie, aarch64), confirmed 2026-03-16.
- Runs: lucos_router, lucos_media_import, lucos_media_linuxplayer, lucos_private, lucos_static_media. pici retired (archived 2026-03-17).
- `build-multiplatform` is standard for arm builds.

## Hostname → Repo Mappings (non-obvious)
- `media-api.l42.eu` → `lucos_media_metadata_api` (Go API)
- `media-metadata.l42.eu` → `lucos_media_metadata_manager` (PHP web UI)
- `ceol.l42.eu` → `lucos_media_manager` (player/queue UI)
- `am.l42.eu` → `lucos_time`
- Verify via `/_info` ci.circle field when in doubt.
