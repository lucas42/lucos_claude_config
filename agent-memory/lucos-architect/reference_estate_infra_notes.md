---
name: estate-infra-notes
description: Standing infrastructure and CI/auto-merge facts about the lucos estate — deploy orb, ARM hosts, host capacity, auto-merge and security-check gaps
metadata:
  type: reference
---

## Auto-merge & security checks

- **lucas42/lucos#42 — CodeQL race.** CodeQL must be a *required status check* (repo settings) or auto-merge can win the race. `lucos_photos`' check name is `Analyze (python)`.
- **Dependabot auto-merge** needs `LUCOS_CI_APP_ID` / `LUCOS_CI_PRIVATE_KEY` present in the **Dependabot** secret scope (not just Actions). See [[github-dependabot-secrets]].
- Auto-merge **caller workflows need at least `permissions: contents: read`** — an empty `{}` yields `startup_failure`.
- The `lucas42/.github` smoke tests cover `dependabot-auto-merge` only, **not** `code-reviewer-auto-merge` (gap tracked as lucas42/lucos#58).

See also [[base-image-bump-incident-class]] — auto-merged base-image bumps are the estate's most repeated production-break class.

## Infrastructure notes

- **CI token migration** (`lucos_deploy_orb` ADR-0001): PAT → App token `lucos-ci`. Callers MUST pass `repositories:["$CIRCLE_PROJECT_REPONAME"]`.
- **CI orb jobs:** `build-multiplatform` (amd64+arm64) vs `build-amd64` (amd64 only).
- **`depends_on` does NOT wait for readiness.** Postgres/DB consumers need startup retry logic of their own.
- **ARM-deployed systems:** `media_import`, `media_linuxplayer`, `private`, `router`, `static_media`.
- **Volume restore gotcha:** a `docker run` against a new volume skips compose labels — use `docker compose`, or apply the labels manually (lucas42/lucos_backups#64).
- **Bulk-deploy waves (Mar 2026):** agent execution speed is a liability unless verification gates run at the same speed.
- **avalon memory pressure** (`photos_worker` + `docker_mirror` OOM) — resist siting new memory-hungry workloads there.
