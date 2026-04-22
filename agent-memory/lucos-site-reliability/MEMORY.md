# SRE Agent Memory

## Loganne — Webhook Retry API

Loganne auto-retries failed webhooks only **once** (`src/webhooks.js`) then gives them up as permanent failures — so a downstream outage lasting more than ~20 seconds (e.g. a rolling monitoring redeploy) will leave events stranded in `status: failure`, which keeps `webhook-error-rate` red forever. **Restarting loganne does NOT clear them** — in-memory failure state survives restart via filesystem persistence, and there's no fresh-retry-on-boot path.

The fix is the retry API (auth-required, Bearer `KEY_LUCOS_LOGANNE`):

- `POST /events/retry-webhooks` — bulk retry, returns `{retriedCount: N}`. 60s global cooldown.
- `POST /events/:uuid/retry-webhooks` — single event retry. 60s per-UUID cooldown. Returns 400 if the event has no failed hooks.

Finding the stuck events: iterate `/events?limit=500` and filter on `e.webhooks.status === 'failure'`. Used 2026-04-21 to clear 3 `deploySystem → monitoring.l42.eu/suppress/clear` failures left by the morning deploy-storm gap.

## Production Host Directory Structure

No persistent per-service directories on production hosts. Docker Compose files deploy transiently to `/home/circleci/project` during CI only. Use container names directly:

```bash
docker logs lucos_monitoring   # correct
docker restart lucos_monitoring
# Wrong: cd /home/docker/lucos_time && docker compose stop
```

Container names match the service name in `docker-compose.yml`.

## Standing Rules

**Keep the docker.l42.eu mirror in the orb.** See [feedback_keep_docker_mirror.md](feedback_keep_docker_mirror.md). Mirror-side bugs (digest-404, etc.) must be fixed at the mirror layer, not by removing the BuildKit mirror config from `publish-docker.yml`. Reason: Docker Hub rate-limit exposure across estate-wide concurrent CI is worse than the mirror's bugs. Confirmed 2026-04-19 when lucas42 rejected PR lucas42/lucos_deploy_orb#143.

**Probe before requesting.** See [feedback_check_before_requesting.md](feedback_check_before_requesting.md). Never file a feature-request issue without first verifying (one curl / one grep) the feature doesn't already exist. Wasted a triage cycle on lucos_schedule_tracker#57 2026-04-19.

**Verify issue state before citing an issue number.** When citing any `#N` in a GitHub issue body, PR, or teammate message as "open", "tracking X", "in progress", etc., verify first with `gh-as-agent repos/lucas42/<repo>/issues/<N> --jq '.state'`. MEMORY.md is truncated in the system prompt (explicit warning at the bottom) — memory snippets may be stale by days or weeks. This bit me on 2026-04-22 when I cited `lucos_docker_mirror#19` (gunicorn saturation) as open in lucas42/lucos#106, but it had been closed since 2026-04-17 after the nginx migration. Don't trust system-prompt-loaded memory for issue state — always verify via API.

**No destructive remediation without a recovery path.** See [feedback_no_destructive_without_recovery_path.md](feedback_no_destructive_without_recovery_path.md). Before `docker rm -f` or similar on a production container, confirm a CI re-deploy or manual re-creation path exists. Applies especially to lucos: compose files live only on CircleCI runners transiently, not persistently on hosts. Bit me 2026-04-22 when I `rm -f`'d `lucos_dns_bind` to test if it cleared an `AlreadyExists` state — it did, but there was no compose file on avalon to recreate it.

**"No deploy event in Loganne" does NOT mean "no deploy happened."** The deploy orb's `Send deploy log to loganne` step is near the END of the deploy job and retries up to 6 times on failure. If every retry fails (e.g. because the deploy itself broke DNS/networking in a way that affects outbound HTTP), the deploy still HAPPENED — the container is running the new image on the host — but no `deploySystem` event gets recorded. **Always confirm a "no deploy today" claim by cross-checking the CircleCI pipeline history for the service AND the actual container `Created` timestamp on the host, not just the Loganne feed.** Learned 2026-04-22 when I misdiagnosed a 20-min `lucos_dns_bind` outage as a "CircleCI DNS blip" because no `deploySystem lucos_dns` event appeared in Loganne for the window.

**Before filing a follow-up issue from an incident report, search for existing open issues on that repo.** The warm-up grace period I proposed in `lucos_monitoring#186` was already implemented by `#87` months ago. The rule in `sre-ops-checks.md` about duplicate-prevention applies to follow-up issues too, not just ops-check-triggered ones. **Also: re-read the commit that closed the issue** — "closed" could mean "implemented" (as with #87) or "won't fix" or "wrong analysis" — the status alone doesn't tell you whether your new issue is different.

**Before claiming a monitoring alert was "self-inflicted" because of a restart, verify the alert fired within the warm-up window.** If it fired >1 min after the monitoring restart, the first-poll-skip protection from `lucos_monitoring#87` already handled that case — the alert is REAL. Look for contemporaneous real causes (concurrent deploys, nginx reloads, host I/O saturation) before blaming the monitor. Learned 2026-04-22 — incorrectly blamed monitoring's state reset for a 25-service alert burst that was actually caused by 7 simultaneous service deploys.

**Never dismiss `loganne webhook-error-rate` as "will clear with time."** It will NOT clear on its own — loganne retries failed webhooks only once, and restarting loganne doesn't re-try them either. The `POST /events/retry-webhooks` API call at the top of this memory file is what clears them. If a webhook-error-rate alert appears during ops checks, ACTIONABLE IMMEDIATELY: retry via the API. Learned 2026-04-22 — I saw the alert during ops checks, noted in memory that the retry API is the fix, and still reported it as "self-healing" in my completion manifest. **When your memory tells you how to fix a thing, FIX IT, don't paraphrase the memory as "transient" and move on.**

**Use the canonical persona name for SendMessage, not the envelope's `teammate_id`.** See [feedback_teammate_id_vs_name.md](feedback_teammate_id_vs_name.md). When replying to `<teammate-message teammate_id="...">`, the `teammate_id` attribute is a harness-internal id, not the target name. Canonical names are filenames in `~/.claude/agents/*.md` (plus `team-lead`).

**Read the full function before editing any part of it.** Partial edits risk removing assignments used further down (caused regression in lucos_backups PR #62).

**Test Locally Before Pushing**: Docker available locally. Always build and run container locally before opening a PR. Pushed untested fixes to production → 3-PR crash-loop incident 2026-03-14.

**Push all content before requesting review**: `lucas42/*` repos have fast auto-merge — if a reviewer approves the PR, it merges within seconds, no merge-queue delay. Pushing new commits *after* review is requested is unsafe: the approval can land and auto-merge the incomplete state before the expansion lands. 2026-04-18: PR#96 (incident report) auto-merged the narrow first version seconds after reviewer approval, before my expanded second commit landed. Had to open PR#97 to fix up. Rule: make all commits, push all of them, THEN request review.

**Diagnostic pattern — proxy in front of content-addressed store**: any time a reverse proxy (nginx, gunicorn, envoy, etc.) sits in front of a content-addressed store (Docker registry, blob storage, IPFS, etc.), a *partial write / mid-stream truncation* on the proxy side surfaces as **multiple different-looking errors upstream** — because the client's integrity check fails in a different spot depending on where in the stream it got cut off. On 2026-04-17 this produced three signatures (`context deadline exceeded`, BuildKit `unexpected commit digest`, `manifest unknown`) all from one gunicorn worker saturation. When you see 2+ distinct error messages from services that talk to the same proxied blob-y dependency, suspect one root cause at the proxy layer before three separate bugs.

**Diagnostic pattern — "used to be fine" = slow-cooker cause**: when a component that was working starts misbehaving and nothing has obviously changed, the default hypothesis should be a gradually-accumulating cause, not a new bug. Check on-disk size, index/cache growth, log volume, table row counts, connection-pool waiters, memory RSS trend. Close-as-symptom fixes (bump the timeout, loosen the threshold) are a warning sign you haven't found the real cause. 2026-04-20 arachne incident: 12 days of TDB2 tombstone accumulation surfaced as two symptom tickets (lucos_arachne#321 raised timeout; lucos_arachne#343 dismissed flapping) before being diagnosed. Always ask "what changed about the data, not the code?" first.

**Memory sizing refactors — check where the bytes went, not where they were**: when a design change removes a memory-heavy component ("we removed the OWL reasoner, saving ~500MB"), verify the replacement isn't just moving the bytes to a different place in the same budget. Pre-computed indexes, materialised views, cached derivations, memoised results — all still cost memory, just at a different time. lucos_arachne PR #268 cut container memory 2G → 1G on the assumption that removing the OWL reasoner freed enough RAM; the replacement (precomputed inferred graph) was persisted to the same TDB2 store and *grew* the mmap footprint. Rule: for any memory reduction PR, require a before/after measurement on production-shaped data before the limit change lands.

## lucos_deploy_orb — Known Patterns
- Issue #21 (port-contention-during-deploy): open. `docker compose up --wait` fails when new container can't bind host port held by old container.
- Issue #42 (closed 2026-03-21): `loganne-publish` command no longer `--fail`s on transient outage. **Scope gap**: `deploy.yml`'s inline "Send deploy log to loganne" step still uses `curl ... --fail` (with `max_auto_reruns: 5` / `auto_rerun_delay: 30s` = 150s retry budget). When loganne itself is the repo being redeployed during an estate wave, the outage can exceed 150s and this step will hard-fail the deploy. If you see this pattern again, the fix would be a separate issue — not a re-open of #42.
- Issue #43 (open): root cause tracking for 2026-03-20 stale CI failures.
- Issue #71 (closed): `depends_on` with `condition: service_healthy` leaves containers stuck in "Created" state when `--wait-timeout` expires. Orb now handles this in retry path (starts `Created` containers before retry).
- **Issue #144 (open, P2) — deploy retries are no-ops when container is `unhealthy`**: the retry logic in `deploy.yml` only handles `Created` state (from #71). If a container is running-but-unhealthy (e.g. first attempt timed out at 120s under load), `docker compose up --wait` on retry exits in 0.7s with terminal `unhealthy` state — never giving it a chance to become healthy. Fix: `docker restart` any `health=unhealthy` containers before retry to reset healthcheck into `start_period`. Observed 2026-04-19 on lucos_eolas + lucos_media_metadata_api during 15-pipeline estate wave (both services were actually healthy minutes later; only CI was red).
- Issue #84 (open, P2): `Docker Tag & Push (Latest)` step tries to push upstream images (postgres, pgvector, owntracks/recorder) that weren't locally built. Affects repos with non-built services in docker-compose. Blocks deploys for lucos_eolas, lucos_contacts, lucos_photos, lucos_locations.
- **calc-version runs on ALL branches** (not just main) — `build-amd64` has no branch filter. Version tags get pushed from branch builds. This caused a token burnout incident on 2026-04-16 when ~57 simultaneous branch builds hit GitHub's abuse detection. Fix needed: check `CIRCLE_BRANCH == main` before pushing tags.
- **Estate-wide rollout + shared token = abuse detection risk**: GitHub flags tokens used for ~50+ simultaneous git push operations from distributed CI runners. Two observed symptoms: (a) 401 "Invalid username or token" (2026-04-16 PAT incident), (b) 403 "Permission to X denied to lucos-ci[bot]" via git-HTTPS even though the App has push access (2026-04-17 during estate-wide Dependabot merge wave; same repo pushed v1.0.7 and v1.0.8 OK at 07:04–07:05 then failed v1.0.9 at 07:07). Token generation API call still succeeds — throttling is at the git-receive-pack layer. Cooldown period unknown. Mitigation: add jitter (`sleep $((RANDOM % 30))`) before `git push` in calc-version, or stagger estate-wide triggers in batches of ~10 with a 2-min gap.
- **CircleCI re-run vs new pipeline**: `rerun from_failed` uses the ORIGINAL pipeline config (including orb version resolved at creation). If the orb has changed, you need to trigger a NEW pipeline via `POST /api/v2/project/.../pipeline` with `{"branch": "main"}` to pick up the new version.
- **Docker Hub rate limit**: Triggering ~86 concurrent builds overwhelms Docker Hub pull limits. Free/basic accounts get 200 pulls/6hrs. Stagger builds or accept transient failures.
- **`lucos-ci` GitHub App (as of 2026-04-16)**: Replaced the old `GITHUB_TOKEN` PAT for CI git push + release creation. Uses `generate-github-token` orb command. Must be granted access to all repos individually.
- **PR #109 mirror-redirect bug — FIXED 2026-04-18 by PRs #125 + #126**: The broad `ghcr.io/lucas42/mirror/*` `--build-context` rewrite was replaced by BuildKit `[registry."docker.io"] mirrors = ["docker.l42.eu"]` config scoped to docker.io only, with probe-and-fallback if the mirror is unavailable. Aftermath: 18 dependabot PRs were left with failing builds (orb version resolved at pipeline creation, so `rerun from_failed` would hit the same bug). Resolution: trigger fresh pipelines via CircleCI v2 API on each branch — they pick up the updated orb.
- **Issue #130 (open, rewritten 2026-04-18) — Simplify push-release-tag.yml**: retry-with-increment loop is architecturally broken. Build order is `calc-version → publish-docker → push-release-tag`; by the time push-release-tag runs, the Docker image is already on Docker Hub tagged with the original VERSION. Bumping the git tag on conflict → silent git/Docker drift. Revised plan: (1) remove outer retry-with-increment loop entirely, (2) drop `push_tag_with_retry` / `create_release_with_retry` bash backoff loops, use CircleCI's native `max_auto_reruns` / `auto_rerun_delay`, (3) make job idempotent (check if tag/release already exists at current HEAD before pushing/creating), (4) fail loudly on unexpected tag conflicts rather than silently bumping. **Depends on #131** (serial-group) to remove main source of conflicts first. Original race observed 2026-04-18 on lucos_arachne (4/5 concurrent pipelines failed), lucos_eolas (1), lucos_docker_health (1); also 2026-04-17 on lucos_notes.
- **CircleCI shell default is `bash -eo pipefail`** — `set -e` is always on. Pattern `func_that_might_fail; rc=$?` is broken: shell exits before `$?` is captured. Always use `rc=0; func_that_might_fail || rc=$?` instead. This bit us in push-release-tag.yml (issue #130).
- **Issue #122 (closed 2026-04-17)**: orb now probes `docker.l42.eu/v2/` at build-start and sets `MIRROR_AVAILABLE=true/false`; "Docker Login (mirror)" no-ops when false; BuildKit is only configured to use the mirror when true. **Scope gap**: the probe is one-shot. If the mirror is reachable at probe time but saturates later (nginx connection refused, TLS handshake timeout mid-build), later steps still try the mirror. Observed 2026-04-21 estate wave — `Docker Login (mirror)` failed with `context deadline exceeded` / `connection refused` despite #122 fix. For true saturation resilience would need either (a) retry the probe in subsequent steps, or (b) fail-closed to upstream Docker Hub on any mirror error during build. Separate issue from #122 if raised.
- **Issue #124 (open, P3)**: orb's own CI lacks a pre-publish test exercising the `:latest` tag push step end-to-end. A driver/tagging mismatch in `publish-docker.yml` (the `docker tag` bug fixed by #120) shipped undetected to production on 2026-04-17 because of this gap. Needs a check that both versioned AND floating tags exist after `publish-docker` runs.
- **`docker tag` + buildx docker-container driver**: `docker buildx` with the `docker-container` driver does NOT load the built image into the host daemon. So `docker tag <image> :latest` followed by `docker push :latest` fails immediately with "No such image". Use `docker buildx imagetools create` instead — server-side manifest tag, no local image required. This was the root cause of 2026-04-17 `publish-docker.yml` bug (fixed by lucas42/lucos_deploy_orb#120); `publish-docker-multiplatform.yml` had already been migrated.
- **`docker buildx bake --set` does NOT split list attributes on comma**. `--set service.tags=a,b` is parsed as ONE tag called "a,b" → `invalid reference format`. To set multiple values on a list attribute, use repeated `--set` invocations with `+=` append form: `--set service.tags=a --set service.tags+=b`. Introduced as estate-wide P1 in lucos_deploy_orb PR #139 (commit 499aea1b, 2026-04-18) — rolled both `:version` and `:latest` into a single comma-joined `--set`, broke every main-branch build. Issue #141.
- Issue #103 (open): `scp … /dev/stdout >> "$BASH_ENV"` **truncates** `$BASH_ENV` — does NOT append. `/dev/stdout` is a symlink to `/proc/self/fd/1`; opening that path re-opens the underlying file with `O_WRONLY|O_CREAT|O_TRUNC` (scp-via-SFTP's default open flags), wiping whatever earlier steps wrote. `>>` on the outer shell is useless against a command that opens its destination as a path. Grep-filter workaround (`scp … /dev/stdout | grep …`) fails too: pipe fd is non-seekable and SFTP's positioned writes silently produce nothing. Fix: use `ssh remote cat file >> "$BASH_ENV"` instead — ssh writes to a real stdout stream. General rule: never use `/dev/stdout` as a command's destination path when you want shell redirection to behave; use `-` or a real stdout-emitting command.

## lucos_docker_mirror — Known Issues & Patterns
- **Architecture (post-2026-04, ADR-0002)**: three containers on avalon — `lucos_docker_mirror_web` (**nginx** reverse proxy, port 8038; NOT gunicorn any more), `lucos_docker_mirror_info` (sidecar for `/_info`), `lucos_docker_mirror_registry` (upstream `registry:2.8.3` pull-through cache). Registry has `mem_limit: 512m`. Containers named with `_web` / `_info` / `_registry` suffixes.
- **Gunicorn is history.** Issue #19 (closed) was the previous architecture. Migration tracked in #21/#22/#23. If you see memory notes about "gunicorn worker saturation" or similar — they're stale, discard.
- **Issue #41 (open, P3) — registry leaks partial blob to client when upstream Docker Hub EOFs mid-stream**: `registry:2` streams blobs through without buffering. If Docker Hub closes the upstream connection mid-stream, the client receives HTTP 200 + partial body + EOF, looking like a successful-but-corrupt blob. BuildKit surfaces this as `unexpected commit digest ... failed precondition`. Observed 2026-04-19 on lucos_configy during a 15-pipeline estate wave (upstream EOF at 36MB of a 269MB `rust:1.95.0-alpine3.22` layer). Cached blob completed on retry, no persistent corruption. Possible fixes: nginx response buffering, pre-warming popular base images, client-side retry on BuildKit digest errors.
- **`unexpected commit digest` is NOT always local saturation.** When debugging, pull the registry logs and look for `err.detail="unexpected EOF"` with `http.response.written=<partial-size>`. If you see that, the fault is upstream (Docker Hub). Our mirror is fine; `docker restart lucos_docker_mirror_web` does nothing useful in this case — the cached layer will complete naturally on the next pull.
- **How to triage the 3 "mirror-ish" CI-side symptoms**:
  1. `Docker Login (mirror): TLS handshake timeout` — usually NOT the mirror; it's a network blip between CircleCI runner and avalon. Retrying almost always works.
  2. `failed to compute cache key: unexpected commit digest ...: failed precondition` — check registry logs first. `unexpected EOF` = upstream hiccup (issue #41). Any 5xx errors clustering + `/_info` timing out from outside but not from avalon = local saturation (unlikely on current nginx architecture).
  3. `manifest unknown` 404s — could be the pre-existing registry:3-not-a-thing trap (see below), or a legitimately-missing upstream image. Not a saturation symptom.
- **`registry:3` (distribution v3) breaks pull-through proxy for OCI image indexes.** Serves cached index manifests, but on digest lookups for child manifests not yet locally stored, does a local-only lookup and 404s in microseconds (no upstream fetch attempted). Dependabot-bumped lucos_docker_mirror from 2→3 on 2026-04-17 → broke every estate multi-platform build. Fix: pin `registry:2` and add dependabot `ignore` for major bumps on `registry`. Tracked in lucos_docker_mirror#35 (closed). `registry:2.8.3` is the current pin. **Issue #39 (open as of 2026-04-19) is the same bug seen from the orb side** — confirmed by lucas42 that it was raised during the registry:3 regression window and is not reproducible on registry:2.8.3 (I verified with a cold ppc64le memcached child-manifest probe). Can be closed.
- **Estate-wide triggers**: 8s stagger is fine for the nginx mirror itself. The failure mode that surfaces at scale now is *upstream* — Docker Hub occasionally EOFs mid-blob when avalon is pulling lots of big layers in parallel. For safety, 20s stagger is a reasonable default when triggering 10+ pipelines at once; pre-warming common base images on avalon beforehand eliminates the upstream path entirely for the hottest layers.
- **Incident report** for the OLD gunicorn era: `docs/incidents/2026-04-17-docker-mirror-overload-and-orb-publish-bug.md` (PR lucas42/lucos#92). Describes a symptom class we no longer see.

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
- **2026-04-20 TDB2 bloat incident** (report: `docs/incidents/2026-04-20-arachne-sparql-timeouts-tdb2-index-bloat.md`): PR #268's `DROP GRAPH` + re-INSERT ingestion pattern grew TDB2 indexes from <100MB to ~93GB in 40 days against 227K live quads. TDB2 B+tree tombstones are never reclaimed without explicit compaction. User-visible SPARQL timeouts, JVM swapping at 99%+ container memory. Resolution via online compaction + memory bump (PR #387). Strategic redesign in #386 (architect recommended: conditional refresh → diff-based → scheduled compaction).
- **TDB2 online compaction command**: `POST /$/compact/arachne?deleteOld=true` via admin auth. Zero downtime, takes ~1 min for our data size, swaps `Data-0001` → `Data-0002` atomically. Use this whenever Fuseki on-disk size grows suspiciously large relative to live quad count (`SELECT (COUNT(*) AS ?n) { ?s ?p ?o }`). Sanity check: healthy ratio is <10× live quad size; 100× or more means bloat.
- Follow-up issues from the 2026-04-20 incident: #388 (SPARQL-latency signal in /_info), #389 (scheduled compaction safety-net), #386 (strategic ingestion redesign with architect).

## lucos_creds — Known Issues
- Issue #199 (open, priority:low): SSH resolution to `lucos-creds` still failing from `lucos_creds_ui` despite `hostname: lucos-creds`. Docker DNS may not register hostname as alias on all network configs.
- Issue #152 (closed 2026-04-10): circular self-deploy dependency fixed — creds no longer needs itself to deploy.
- Issue #257 (closed 2026-04-16): creds SSH briefly unavailable during redeploy waves was deemed already addressed by `max_auto_reruns: 5` + `auto_rerun_delay: 30s` on `Populate known_hosts` (150s retry budget, added in orb commit `acb6704` on 2026-04-04). **Scope gap**: during the 2026-04-21 estate wave, creds' own redeploy outage exceeded 150s for some repos → all 5 retries burned, `getaddrinfo creds.l42.eu: Temporary failure in name resolution` → hard CI fail. If this recurs during a future large wave, the fix is either to extend the retry budget or to sequence creds' own deploy earlier so its outage ends before other repos need it. Separate issue if raised — do NOT re-open #257.

## Monitoring API Structure

**`/api/status` response**: `systems` is a **dict keyed by URL/name** (not a list). `checks` within each system is also a **dict keyed by check name** (not a list). Check for failures with `check.get('ok') == False` (not just falsy — missing `ok` means passing). Correct pattern:

```python
data = json.load(...)
for url, s in data['systems'].items():
    for cname, c in s.get('checks', {}).items():
        if c.get('ok') == False:
            print(url, cname, c.get('value',''))
```

## lucos_schedule_tracker — API
- `DELETE /schedule/{system}` — idempotent, returns 204, no auth. Shipped in PR #56, 2026-04-18. Use for cleaning up stale tracked jobs when a scheduled runner stops reporting (e.g. when a metric is removed from a health-check service).

## lucos_monitoring — Known Issues
- Issue #148 (open, priority:low, owner:lucos-site-reliability): CircleCI check errors on repos with 0 active pipelines (`.github` has no CI config; `vue-leaflet-antimeridian` has config but project not activated). Fix: return neutral/unknown when 0 pipelines instead of erroring.
- Issue #178 (open, P3): transient CircleCI workflow-fetch blip on the MOST RECENT pipeline lets a failed workflow from an OLDER pipeline win `keepLatestWorkflowPerName`, producing a false-positive `ok=false` for exactly one polling interval (~60s). Pattern: alert → recovery 60s later with no pipeline activity. `collectAllWorkflows` in `fetcher_circleci.erl` silently returns `[]` on HTTP error for each pipeline's workflow endpoint; if the most recent pipeline's fetch fails, only older pipelines contribute and an old failure can become the "latest". Fix: bail to `ok => unknown` if the most-recent pipeline's workflow fetch fails.
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
- Issue #159 (closed 2026-04-12 via PR #160): IPv6 route flap from avalon to salvare — salvare has AAAA only, route from OVH occasionally unreachable. Fix routes Fabric connections via xwing ProxyJump. **PR #160 fix was incomplete — only covers `Host.__init__`'s primary connection, not the raw `ssh` / `scp` commands in `copyFileTo` and `fileExistsRemotely` (host.py:77, 82). Those still go direct and still fail on IPv6 route flaps. Tracked by lucos_backups#185 (open, P2).** Symptom on recurrence: schedule-tracker.l42.eu alerts on `lucos_backups` check with `ssh: connect to host salvare.s.l42.eu port 22: No route to host`. Backup /_info itself shows all checks OK — failure is in the cron scheduled run, not the live service. Alert clears only on next successful scheduled run (next ~03:25 UTC).

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
- **Docker Hub rate limit hits at DEPLOY time, not build time** (2026-04-22): the `docker.l42.eu` mirror is wired via orb BuildKit config → covers CircleCI runner builds only. `lucos/deploy-*` uses `DOCKER_HOST=ssh://` to drive the remote host's Docker daemon, which runs `docker compose pull` directly against `registry-1.docker.io` — unauthenticated, 100/6hr per-IP. Estate-wide rollouts of ~37 repos blow this immediately. Symptom: all `lucos/deploy-avalon` jobs fail at `Pull container(s) onto remote box` with `toomanyrequests: unauthenticated pull rate limit`; `lucos/build` succeeds on the same workflow. Fix: add `registry-mirrors` to `/etc/docker/daemon.json` on avalon/xwing/salvare (sysadmin). Tracked in lucas42/lucos#106. First occurrence exposed it; not caused by the rollout — latent gap revealed by concurrent deploy load.
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
- **Bind-mounts of local files don't work with `DOCKER_HOST=ssh://` remote deploys.** The lucos deploy orb runs `docker compose up` against the remote Docker daemon on avalon/salvare/etc. Bind-mount sources (e.g. `./config.yml:/container/path`) are resolved on the **remote host's** filesystem, NOT the CircleCI runner's. The source file doesn't exist there, Docker auto-creates it as an empty directory, then `runc` fails with `not a directory: Are you trying to mount a directory onto a file`. Fix: use env vars or `COPY` config into the image. First hit: lucos_docker_mirror#5 on 2026-04-17 (initial deploy of new service).
- **`registry:3` (distribution v3) breaks pull-through proxy for OCI image indexes.** Serves cached index manifests, but on digest lookups for child manifests not yet locally stored, does a local-only lookup and 404s in microseconds (no upstream fetch attempted). Dependabot-bumped lucos_docker_mirror from 2→3 on 2026-04-17 → broke every estate multi-platform build. Fix: pin `registry:2` and add dependabot `ignore` for major bumps on `registry`. Tracked in lucos_docker_mirror#35. registry:2.8.3 confirmed working via direct test: same digest that 404'd in 446µs now returns 200 in ~500ms with `Accept: application/vnd.oci.image.manifest.v1+json`.
- **`REGISTRY_PROXY_PASSWORD` is optional in registry:2/3 proxy mode.** Without it, upstream pulls go anonymous (100/6hr/IP Docker Hub rate limit). Registry still starts healthy. Useful to know for emergency manual deploys where creds aren't available — degraded but functional.
- **Manual container swap protocol** (when CI deploy is blocked but image is on Docker Hub):
  1. `ssh <host> 'docker inspect <name> --format "{{json .}}"'` → extract env/network/volume/healthcheck/memory
  2. Baseline monitoring (`curl https://monitoring.l42.eu/api/status`)
  3. `docker stop <name> && docker rm <name>`
  4. `docker run -d --name <same> --network <from-inspect> -v <volume> --restart always --health-cmd ... <image>:<version>`
  5. Wait for healthy (`docker inspect --format '{{.State.Health.Status}}'`)
  6. Wait 2min, recheck monitoring
  7. Document via GitHub issue comment — what was done, why, and what self-heals on next CI
- **SRE doesn't have production creds SCP access.** `scp -P 2202 creds.l42.eu:<system>/production/.env` → Permission denied (publickey). Only lucas42 key has production read. Agents have development read+write only. Don't waste time trying — escalate to lucas42 or deploy degraded.
- **Docker Hub rate limit cascades in CI**: when mirror is broken, every CI pipeline pulls directly from Docker Hub, exhausting the shared lucas42 pull rate limit. `imagetools create` in `Docker Tag & Push (Latest)` is especially exposed because it does a manifest GET which counts as a pull. Symptom: pipeline builds+pushes successfully then fails at tag-latest with `429 Too Many Requests / toomanyrequests: You have reached your pull rate limit as 'lucas42'`. Fix: orb#137 (push both tags at build time, eliminate tag-latest round-trip).

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
