---
name: pattern-repo-test-job-bypasses-docker-mirror
description: Repo-owned CircleCI `test` jobs using bare setup_remote_docker pull direct from Docker Hub with no docker.l42.eu mirror, so a transient Hub error reds the job and blocks deploy — while lucos/build in the same pipeline survives via the orb's mirror
metadata:
  type: project
---

A red `ci/circleci: test` on a lucos repo whose config hand-rolls its own `test` job is **often not a test failure at all** — check whether the job even reached the tests before reading the diff.

The shape: `test` uses a bare `setup_remote_docker` + `docker compose --build`, which pulls straight from Docker Hub. The orb's `publish-docker` command (used by `lucos/build`) probes `docker.l42.eu`, configures BuildKit to use it as a registry mirror, and falls back to direct Hub if unreachable. **`test` gets none of that.** So a Docker Hub blip fails `test` while `lucos/build` in the same pipeline, at the same minute, pulling the same base image, succeeds — and because `lucos/deploy-avalon` requires `test`, the merged change silently stops deploying.

**Fingerprint** (2026-08-31, lucos_contacts pipeline 1769, job 5284):
`=> ERROR [test internal] load metadata for docker.io/library/python:3.14-alpine` →
`failed to solve: ... failed open: unexpected status from GET request to docker-images-prod.s3...amazonaws.com ... 400 Bad Request` → `Exited with code exit status 17`.
Died 10s in, zero tests run. Bare re-run of the identical commit passed.

**Diagnostic shortcut:** if the failing step is base-image metadata resolution, compare against the `lucos/build` job's `Configure BuildKit registry mirror` step in the same workflow. `Mirror is reachable (HTTP 401), configuring BuildKit to use it` there + a direct-Hub error in `test` is the tell. A 401 probe response is *success* (the mirror requires auth), not a failure.

**Affected repos** (own job + `setup_remote_docker`, no mirror), surveyed 2026-08-31: `lucos_contacts`, `lucos_backups`, `lucos_media_import`, `lucos_media_metadata_manager`, `lucos_aithne`. Not affected (plain docker executor): `lucos_arachne`, `lucos_repos`, `lucos_creds`, `lucos_monitoring`.

**Mirror mechanism (read from `src/commands/publish-docker.yml`, 2026-08-31) — three gotchas for anyone adopting it:**
1. It configures **BuildKit only** (writes `/tmp/buildkitd.toml`, `docker buildx create --use --name builder --config`). A plain **daemon** pull (`docker pull` / `docker create`) does NOT consult it. So `lucos_aithne`'s exposure — `docker create lucas42/lucos_auth_scopes@sha256:…` in its `fetch-scopes` job, not `test` — is NOT fixed by the same change.
2. The mirror **requires auth** (probe returns 401 = success). `publish-docker` follows the probe with `docker login docker.l42.eu`.
3. `DOCKER_MIRROR_USERNAME`/`_ACCESS_TOKEN` are **not** CircleCI project or context env vars (both empty for lucos_contacts/lucos_aithne; only org contexts are `circleci-agents`, `orb-publishing`). They come from the orb's `fetch-publish-creds`, which `scp`s an envfile from `creds.l42.eu:2202` over SSH. So a repo-owned job needs creds-fetch + configure + login, not one step.
4. ⚠️ **`fetch-publish-creds` has a big blast radius**: it `scp`s `lucos_deploy_orb/publish/.env` *wholesale* into `$BASH_ENV`. Consumers show it carries `LUCOS_CI_PEM` (GitHub App key → repo-write installation tokens), `DOCKERHUB_ACCESS_TOKEN` (push), `TWINE_PASSWORD` (PyPI), as well as `DOCKER_MIRROR_*`. Never pull it into a `test` job to get two mirror vars. By contrast the mirror credential itself is low-value: `lucos_docker_mirror` = single nginx HTTP Basic pair + registry with `proxy.remoteurl` set (pull-through-cache mode ⇒ pushes refused), so it's read-only.
5. **`MIRROR_AVAILABLE=false` is NOT fail-open** — the buildx builder already exists pointing at the mirror, so builds still 401. Failure paths must `docker buildx rm builder` and recreate without the mirror config.
6. Test harness for all of this already exists: `.circleci/test-deploy.yml` `test-publish-docker-with-mirror` runs a local `registry:2` behind htpasswd on `localhost:5001` (`mirror_insecure: true`).

⚠️ Adopting the mirror in a **required** `test` job before lucas42/lucos_deploy_orb#188 (mirror *login* fail-open) lands makes the deploy path depend on Hub **and** docker.l42.eu — a net increase in deploy blockers. Probe falls back cleanly; login does not.

**Why:** the estate already owns the insulation via the orb; it just isn't wired into jobs repos write themselves. Tracked as lucas42/lucos_deploy_orb#197 (extract the mirror-config block into a reusable `configure-docker-mirror` command); adoption across the five repos is lucas42/lucos_deploy_orb#198 (filed 2026-08-31, blocked on #197). Adjacent but distinct: lucas42/lucos_deploy_orb#188 (mirror *login* should fail open).

**How to apply:** on any red `test` in these repos, read the failing step's log before assuming code. If it's a registry error, re-run the workflow (`POST /api/v2/workflow/{id}/rerun` with `{"from_failed": true}`) to restore the deploy, then check whether #197 has landed. Caveat: the mirror is a pull-through cache, not a shield — a cold layer still proxies to Hub. Related: [[feedback-keep-docker-mirror]], [[pattern-baseimage-bump-runtime-break]].
