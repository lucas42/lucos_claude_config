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
- **`/check-runs` alone does NOT show a PR's full check picture — CircleCI reports via the commit-*statuses* API.** GitHub Actions → `repos/…/commits/{sha}/check-runs`; CircleCI (`ci/circleci: test`, `ci/circleci: build`, serial-group markers) → `repos/…/commits/{sha}/status`. Query **both** before concluding anything about CI state; `/check-runs` on its own made two of us read `lucos_creds` #472/#484 as "waiting on CI" when every *required* check was already green (2026-08-06). Required contexts live in branch protection, which the bot Apps 403 on — ask system-administrator (admin scope) rather than inferring. Useful proxy meanwhile: `mergeable_state: unstable` = required checks satisfied, some non-required check red; `blocked` = a required one is not.
- **A cancelled Actions run is terminal — it never self-heals.** During the 2026-08-06 Actions incident, `convention-check` jobs recorded *zero steps* and sat ~15 min awaiting a runner before being killed. "Waiting for CI to clear" on such a run waits forever; it needs an explicit re-trigger. Check for queued/in-progress runs (`actions/runs?branch=…`) before accepting anyone's "CI is stuck" as a live state — including a re-run that already failed (`run_attempt: 2`). Diagnostic bonus: CircleCI ran normally in the same window, a clean Actions-only signature.

- **On a SUPERVISED repo, amending an approved-but-unmerged PR is cheap — don't let "it would reset the approvals" veto a correction.** The bot approvals are not the merge gate there (lucas42's are), so the only cost is a bot re-review loop, measured at **~3 minutes** on `lucos_creds` PRs #472/#484 (push → both bots re-approved). A long wait on such a PR is the *human* queue, which a re-review doesn't touch. Check two things before deciding: has lucas42 reviewed yet (if not, nothing of his is invalidated and he reads the better document), and is the repo supervised (`check-unsupervised`). An unmerged ADR is the cheapest moment there will ever be to fix a decision record. A push *does* dismiss existing approvals — verified via `mergeable_state` flipping `clean` → `blocked` — so always re-request review after.

See also [[base-image-bump-incident-class]] — auto-merged base-image bumps are the estate's most repeated production-break class.

## Infrastructure notes

- **CI token migration** (`lucos_deploy_orb` ADR-0001): PAT → App token `lucos-ci`. Callers MUST pass `repositories:["$CIRCLE_PROJECT_REPONAME"]`.
- **CI orb jobs:** `build-multiplatform` (amd64+arm64) vs `build-amd64` (amd64 only).
- **`depends_on` does NOT wait for readiness.** Postgres/DB consumers need startup retry logic of their own.
- **ARM-deployed systems:** `media_import`, `media_linuxplayer`, `private`, `router`, `static_media`.
- **Volume restore gotcha:** a `docker run` against a new volume skips compose labels — use `docker compose`, or apply the labels manually (lucas42/lucos_backups#64).
- **Bulk-deploy waves (Mar 2026):** agent execution speed is a liability unless verification gates run at the same speed.
- **avalon memory pressure** (`photos_worker` + `docker_mirror` OOM) — resist siting new memory-hungry workloads there.
