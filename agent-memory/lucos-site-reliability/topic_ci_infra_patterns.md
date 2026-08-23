---
name: topic-ci-infra-patterns
description: lucos_deploy_orb known patterns, lucos_docker_mirror architecture/issues, and estate-wide infrastructure/docker/CI patterns (healthchecks, volumes, DOCKER_HOST=ssh deploys, rate limits, manual container swap protocol, GitHub Actions branch-protection gotchas)
metadata:
  type: reference
---

Consolidated from MEMORY.md 2026-07-03 (index compaction). Verify open/closed ticket state before citing.

## lucos_deploy_orb — Known Patterns
- #21 (open, port-contention): `docker compose up --wait` fails when new container can't bind host port held by old.
- #42 (closed): `loganne-publish` no longer `--fail`s on transient outage. Scope gap: `deploy.yml`'s inline "Send deploy log to loganne" still `curl … --fail` (`max_auto_reruns:5`/`auto_rerun_delay:30s`=150s). When loganne itself redeploys during a wave, outage can exceed 150s → hard-fail. Fix = separate issue, not re-open #42.
- #43 (open): root-cause tracking for 2026-03-20 stale CI failures.
- #71 (closed): `depends_on` `condition: service_healthy` left containers stuck "Created" when `--wait-timeout` expired. Orb now starts Created containers before retry.
- **#144 (open P2)**: deploy retries are no-ops when container is `unhealthy` — retry logic only handles `Created` (#71). Running-but-unhealthy → `docker compose up --wait` on retry exits 0.7s terminal `unhealthy`. Fix: `docker restart` any `health=unhealthy` before retry to reset into start_period. Observed 2026-04-19 eolas + mma (both healthy min later, only CI red).
- #84 (open P2): `Docker Tag & Push (Latest)` tries to push upstream images (postgres, pgvector, owntracks/recorder) not locally built. Blocks eolas, contacts, photos, locations.
- **calc-version runs on ALL branches** (`build-amd64` no branch filter) → version tags pushed from branch builds. Caused 2026-04-16 token-burnout (~57 simultaneous branch builds hit GitHub abuse detection). Fix: check `CIRCLE_BRANCH==main` before pushing tags.
- **Estate rollout + shared token = abuse detection**: GitHub flags ~50+ simultaneous git pushes. Symptoms: (a) 401 "Invalid username or token"; (b) 403 "Permission denied to lucos-ci[bot]" via git-HTTPS despite push access (throttle at git-receive-pack layer; token-gen still succeeds). Mitigation: jitter `sleep $((RANDOM%30))` before push, or batch ~10 with 2-min gap.
- **rerun vs new pipeline**: `rerun from_failed` uses ORIGINAL pipeline config (orb version resolved at creation). Orb changed → trigger NEW pipeline `POST /api/v2/project/.../pipeline {"branch":"main"}`.
- Docker Hub rate limit: ~86 concurrent builds overwhelms pull limits (200/6hr free). Stagger.
- `lucos-ci` GitHub App (2026-04-16) replaced old `GITHUB_TOKEN` PAT for CI push+release. Must be granted each repo.
- #109 mirror-redirect bug FIXED 2026-04-18 (PRs #125+#126): broad `ghcr.io/lucas42/mirror/*` rewrite → BuildKit `[registry."docker.io"] mirrors=["docker.l42.eu"]` scoped to docker.io + probe-and-fallback. Aftermath: 18 dependabot PRs left failing (orb resolved at creation) → trigger fresh pipelines.
- #130 (open, rewritten): simplify push-release-tag.yml; retry-with-increment loop broken (image already pushed with original VERSION by push-release-tag time → git/Docker drift). Plan: remove outer loop, drop bash backoff (use native rerun), idempotent (check tag/release at HEAD), fail loud on unexpected conflict. Depends #131.
- **CircleCI shell = `bash -eo pipefail`** (`set -e` always on). `func; rc=$?` broken (exits before capture). Use `rc=0; func || rc=$?`.
- #122 (closed): orb probes `docker.l42.eu/v2/` at build-start → `MIRROR_AVAILABLE`. Scope gap: one-shot probe; mirror can saturate later (`context deadline exceeded`/`connection refused` 2026-04-21). Would need per-step retry or fail-closed to Hub. Separate issue.
- #124 (open P3): orb CI lacks pre-publish test of `:latest` tag push end-to-end (the #120 `docker tag` bug shipped undetected).
- **`docker tag` + buildx docker-container driver**: buildx doesn't load image into host daemon → `docker tag <image> :latest` then push fails "No such image". Use `docker buildx imagetools create` (server-side manifest tag). Root cause of 2026-04-17 publish-docker.yml bug (#120).
- **`docker buildx bake --set` does NOT comma-split list attrs**: `--set svc.tags=a,b` = ONE tag "a,b" → invalid reference. Use repeated `--set svc.tags=a --set svc.tags+=b`. #141 (broke every main build 2026-04-18).
- #163 (open P3): `serial-group: <slug>/build` (#131, no branch filter) serialises PR pipelines too. Burst of ~15 pipelines + ~6min build → tail PRs wait 60+min; GitHub shows no `ci/circleci: lucos/build` status (blocked jobs post no pending) → `mergeable_state: blocked` looks like missing required check. `autocancel_builds:false` on photos → empty commit doesn't help. Fix: branch-scoped serial-group / branch filter / skip tag-push on non-main.
- #103 (open): `scp … /dev/stdout >> "$BASH_ENV"` **truncates** BASH_ENV (SFTP opens path O_TRUNC). Grep-filter workaround fails (non-seekable pipe). Fix: `ssh remote cat file >> "$BASH_ENV"`. Never use `/dev/stdout` as a command destination path for shell redirection.

## lucos_docker_mirror — Architecture & Issues
- Post-2026-04 (ADR-0002): three avalon containers — `_web` (**nginx** reverse proxy, port 8038, NOT gunicorn), `_info` (sidecar `/_info`), `_registry` (`registry:2.8.3` pull-through, `mem_limit:512m`).
- **Gunicorn is history** (#19 closed). Discard stale "gunicorn worker saturation" notes.
- #41 (open P3): registry leaks partial blob when upstream Hub EOFs mid-stream (`registry:2` streams without buffering) → client gets 200+partial+EOF → BuildKit `unexpected commit digest … failed precondition`. Observed 2026-04-19 configy (EOF at 36MB of 269MB rust layer). Completes on retry, no persistent corruption. Fix candidates: nginx buffering / pre-warm / client retry.
- **`unexpected commit digest` NOT always local saturation**: pull registry logs, look for `err.detail="unexpected EOF"` + partial `http.response.written` → fault is upstream Hub; `docker restart _web` does nothing, cached layer completes on next pull.
- **Triage the 3 mirror-ish CI symptoms**: (1) `Docker Login (mirror): TLS handshake timeout` — usually network blip runner↔avalon, retry works; (2) `failed to compute cache key: unexpected commit digest` — check registry logs, `unexpected EOF`=upstream (#41); (3) `manifest unknown` 404 — registry:3 trap or legit missing upstream image, not saturation.
- **`registry:3` breaks pull-through for OCI image indexes**: local-only child-manifest lookup 404s in µs (no upstream fetch). Dependabot 2→3 on 2026-04-17 broke every multi-platform build. Fix: pin `registry:2`, dependabot-ignore major bumps on registry. #35 (closed). #39 (orb side, closeable — not reproducible on 2.8.3).
- Estate triggers: 8s stagger fine for nginx mirror; failure at scale is upstream Hub EOF. 20s stagger for 10+ pipelines; pre-warm hot base images.
- Old-gunicorn-era incident: `docs/incidents/2026-04-17-docker-mirror-overload-and-orb-publish-bug.md` (symptom class no longer seen).

## Infrastructure Patterns
- **Docker Hub rate limit hits at DEPLOY time, not build** (2026-04-22): mirror covers CircleCI runner builds only; `lucos/deploy-*` uses `DOCKER_HOST=ssh://` → remote host runs `docker compose pull` against `registry-1.docker.io` unauthenticated (100/6hr/IP). ~37-repo rollout blows it. Symptom: all `deploy-avalon` fail at `Pull container(s) onto remote box` `toomanyrequests`; `lucos/build` succeeds same workflow. Fix: `registry-mirrors` in `/etc/docker/daemon.json` on avalon/xwing/salvare (sysadmin). lucos#106.
- `depends_on` only waits for container START — use `pg_isready`/equiv in entrypoints.
- **`eaddrinuse` crash-loop**: new container fails when old holds host port; `restart:always` retries forever. Symptom: exit 0, restart count climbing, `eaddrinuse` in logs. lucos_monitoring#50 / lucos_deploy_orb#21.
- **Missing PORT in deploy .env → silent no-host-port-binding**: container healthy internally but router 502. Diagnose `docker port <container>` empty. Fix: retrigger CI after creds corrected. Incident lucos#53.
- **Healthcheck tool by base image**: `nginx:N` (Debian)=curl not wget; Alpine=wget not curl; `openjdk:N-jdk-slim`=NEITHER (install curl). Wrong tool → permanently unhealthy → dependents stuck Created.
- `docker compose up` does NOT stop removed services — manually stop/remove deleted-service containers, and remove their `/_info` check (stale checks alert after container disappears).
- Redis `redis:7-alpine` persistence disabled by default — not durable-queue-safe without AOF/RDB.
- `lucos_monitoring` fetches `/_info` with 1s hard timeout — checks inside must complete <0.5s.
- Docker service names with underscores may fail DNS in Alpine (musl) — set `hostname:` hyphenated.
- **Branch protection `Analyze (actions)` vs `CodeQL` mismatch**: no-source repos run CodeQL "default setup" (github-advanced-security app) → check name `CodeQL` conclusion `neutral`; `neutral` does NOT satisfy a required check. If protection requires `Analyze (actions)` (Actions, app_id 15368), Dependabot PRs block permanently. Fix: remove `Analyze (actions)` from required checks (sysadmin). Affected lucos_private, lucos_static_media (2026-04-10).
- Named Docker volumes must appear in `services.<name>.volumes`, top-level `volumes:`, AND `lucos_configy/config/volumes.yaml`.
- **Bind-mounts don't work with `DOCKER_HOST=ssh://` remote deploys**: source resolved on REMOTE host fs, not runner → Docker auto-creates empty dir → runc `not a directory`. Fix: env vars or `COPY` into image. First hit docker_mirror#5 (2026-04-17).
- **`REGISTRY_PROXY_PASSWORD` optional** in registry:2/3 proxy mode — without it upstream pulls go anonymous (100/6hr/IP); registry still starts healthy.
- **Manual container swap protocol** (CI blocked, image on Hub): (1) `docker inspect <name> --format '{{json .}}'` → env/network/volume/healthcheck/memory; (2) baseline `curl https://monitoring.l42.eu/api/status`; (3) `docker stop && docker rm`; (4) `docker run -d --name <same> --network <net> -v <vol> --restart always --health-cmd … <image>:<ver>`; (5) wait healthy; (6) wait 2min, recheck monitoring; (7) document via issue comment.
- **SRE has NO production creds SCP access**: `scp -P 2202 creds.l42.eu:<system>/production/.env` → Permission denied. Only lucas42 key has prod read; agents dev read+write only. Escalate or deploy degraded.
- **Docker Hub rate limit cascades in CI**: broken mirror → every pipeline pulls from Hub, exhausting shared lucas42 limit. `imagetools create` in Tag&Push(Latest) exposed (manifest GET counts as pull). Symptom: build+push OK then fail at tag-latest `429/toomanyrequests as 'lucas42'`. Fix orb#137 (push both tags at build time).
- **Docker daemon config: prefer `systemctl reload docker` (SIGHUP) over restart**. Hot-reloadable: registry-mirrors, live-restore, labels, insecure-registries, debug, max-concurrent-downloads/uploads. Full restart with `live-restore:false` SIGKILLs every container (2026-04-22 avalon). First question on any daemon.json change: "can this be SIGHUP'd?" Enabling live-restore is itself hot-reloadable.

## Ops-checks / CI facts
- Tracking file `ops-checks.md` records last-run timestamps + per-container log-review history. **7 checks** (not 6); mandatory completion manifest table. See `~/.claude/agents/sre-ops-checks.md`.
- CircleCI v2 API: extract token `cut -d'"' -f2`. Pipeline `state` always "created" — check workflow state separately.
- `lucos-site-reliability` app has NO org-level repo list access — use sandbox list or per-repo API.
- CI monthly check: `curl -s "https://circleci.com/api/v1.1/project/github/lucas42/{repo}?limit=3&filter=completed"` (no auth). v2 rerun: `POST https://circleci.com/api/v2/workflow/{id}/rerun -d '{"from_failed":true}'`.
- _info spec: `~/.claude/references/info-endpoint-spec.md` + lucos/docs (lucos#35 closed).

## CircleCI API gotchas
- ⚠️ **Insights endpoint is main-only and `all-branches=true` is a no-op.** `/insights/.../workflows/build-deploy/jobs/test` silently omits PR/Dependabot-branch failures; identical output with and without `all-branches=true` is the tell, not corroboration. Burned me 2026-08-23 (published "not failed in CI once in 90 days"; it had red'd 5 days earlier and blocked a PR 38h48m). Rule now in `agents/sre-circleci-api.md`.
- **CircleCI caches are shared across branches within a project.** A `save_cache` on a feature branch restores on `main` — verified 2026-08-23, lucos_repos job 2723 (branch) → 2728 (main). So a PR branch warms main's cache; don't assume the first post-merge pipeline is a cold miss.
- `save_cache` with an existing key is a genuine no-op ("Skipping cache generation, cache already exists"), so no conditional guard is needed around it.
- `monitoring` status `pending_verification` (not `unknown`/`failing`) is the normal post-deploy state and counts as `unknown` in `summary`. All child checks healthy + `pending_verification` = settling, not broken.

## Monitoring /api/status structure
`systems` = dict keyed by URL/name (not list); `checks` per system = dict keyed by check name. Failure = `c.get('ok') == False` (missing `ok` = passing):
```python
for url, s in data['systems'].items():
    for cname, c in s.get('checks', {}).items():
        if c.get('ok') == False: print(url, cname, c.get('value',''))
```

## GitHub API / App conventions
- Always `--app lucos-site-reliability` with `gh-as-agent`; never raw `gh api`/`gh pr create`.
- New comment → issue-scoped `repos/lucas42/{repo}/issues/{n}/comments --method POST`. **Footgun**: POST to `repos/.../issues/comments/{comment_id}` OVERWRITES that comment; edit uses `--method PATCH`. (Burnt on deploy_orb#105 2026-04-17.)
- File-backed body needs `@`: `-F body=@FILE` (or `--field "body=@FILE"`); `--field body-file=FILE` posts empty body silently.
- Heredoc `<<'ENDBODY'` for bodies with newlines/backticks.
- `@dependabot` commands require push access — no agent app has it; escalate to lucas42.
- `lucos` repo has auto-merge — don't tell lucas42 to manually merge.
- **Branch protection — BOTH axes vary (endpoint AND App).** `/branches/{branch}/protection` 403s "Resource not accessible by integration" for `lucos-architect` and `lucos-issue-manager`, but 200s for `lucos-site-reliability`. `/branches/{branch}` 200s for all of them and embeds `.protection.required_status_checks.contexts`. Verified 2026-08-06 across three Apps.
  - **The only instruction worth keeping: call `/branches/{branch} --jq '.protection'` and read it.** Correct regardless of which App you are — route to nobody.
  - ⚠️ I got this wrong twice in one evening, in *opposite* directions: first "my App can, yours can't → send reads to me" (invented a routing bottleneck), then over-correcting to "it's purely the endpoint, not the App" (also false). Three agents each generalised a permissions story from a single API call. Diagnose *which endpoint* 403'd AND *which App* called it before concluding anything.
  - Meta-lesson (from `lucos-architect`): this one rule was revised 4× in a day; the first three revisions each added a precondition/disjunction/routing hop, only the last removed one. **When a rule needs patching twice in quick succession, suspect its existence rather than its wording.**
- The two endpoints also differ by **schema**: `/protection` returns 11 keys (`enforce_admins`, `allow_force_pushes`, `required_conversation_resolution`, `lock_branch`…); `/branches/{branch}.protection` returns only **2** — `enabled` and `required_status_checks` (with `enforcement_level` nested *inside* `required_status_checks`, alongside `checks` and `contexts`). So for contexts either works; for anything else you need `/protection`. (I first published "3 keys" from misreading nesting in my own output — `jq '.protection | keys'` rather than eyeballing it.)
- ⚠️ **Unprotected branch: the plain path does NOT error.** `/branches/{branch}` returns **200** with `protected: false`, `protection.enabled: false`, `contexts: []` (verified on `lucas42/lucos`). Only the sub-path `/protection` 404s `"Branch not protected"`. So on the plain path **`.protected` is the signal — never infer from `contexts: []`**, which cannot distinguish "unprotected" from "protected with no required checks". Credit: team-lead, 2026-08-06.
- Reading protection settles "is X *really* a required check?" — `required_status_checks.contexts` lists them. ⚠️ But **`required_pull_request_reviews` is ABSENT (not null) from `/protection` on all 7 protected repos tested** — don't read a `--jq` `null` as "no review requirement configured"; that's a missing-key artefact and I have no positive control showing the key present anywhere. See [[feedback_jq_on_error_response]]. `main` on these repos has no *observed* review requirement; state it that way.
- Branch not protected at all → `/protection` 404s `"Branch not protected"` (e.g. the `lucos` repo). Clean signal, but **sub-path only** — see the plain-path caveat above.

## Loganne webhook retry ops
- Loganne auto-retries a failed webhook only ONCE (`src/webhooks.js`) then permanent-fails; a >~20s downstream outage strands events `status:failure` → `webhook-error-rate` red forever. Restart does NOT clear (filesystem-persisted, no retry-on-boot).
- Bulk: `POST /events/retry-webhooks` (Bearer `KEY_LUCOS_LOGANNE`) → `{retriedCount}`, 60s cooldown. Single: `POST /events/:uuid/retry-webhooks`, 60s/UUID, 400 if no failed hooks.
- Find stuck: iterate `/events?limit=500`, filter `e.webhooks.status==='failure'`. Events API default 7-day window.

## Production host structure / creds self-deploy
- No persistent per-service dirs on hosts; compose deploys transiently to `/home/circleci/project` during CI only. Use container names directly (`docker logs lucos_monitoring`). Names match docker-compose service names.
- **lucos_creds reads `.env` from CircleCI `LUCOS_DEPLOY_ENV_BASE64` snapshot, not creds.l42.eu** (see reference_lucos_creds_self_deploy.md). Live store changes don't propagate until snapshot refreshed. On "fix didn't take after redeploy" for creds, check snapshot first (2026-05-09 CRLF incident).
