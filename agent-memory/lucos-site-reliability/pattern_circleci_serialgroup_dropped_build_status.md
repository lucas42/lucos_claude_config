---
name: pattern-circleci-serialgroup-dropped-build-status
description: PR blocked because CircleCI dropped the inner `ci/circleci: build` status while serial-group wrapper contexts delivered; fix is a workflow re-run
metadata:
  type: project
---

# CircleCI serial-group drops the inner `build` status → PR stuck `blocked`

Repos using the `lucos/deploy` orb with a `serial-group` on the build job (e.g. lucos_router: `serial-group: <<pipeline.project.slug>>/build/<<pipeline.git.branch>>`) report **three** GitHub commit-status contexts per pipeline:

- `ci/circleci: build-deploy/serial-start-1` (the lock job)
- `ci/circleci: build` (the actual `lucos/build` job — this is the required check)
- `ci/circleci: build-deploy/serial-end-1` (the unlock job)

**Failure mode:** CircleCI occasionally fails to deliver the inner `ci/circleci: build` status to GitHub even though the `lucos/build` job *ran and succeeded*. The two wrapper contexts deliver fine, so the PR superficially looks green — but the required check `ci/circleci: build` is absent, so `mergeable_state: blocked` and GitHub-native auto-merge sits armed-but-waiting forever.

**Diagnostic signature:**
- `mergeable: true`, `mergeable_state: blocked`, all visible checks green, approvals on head SHA.
- `repos/.../commits/<sha>/status` shows `serial-start-1` + `serial-end-1` but **no `ci/circleci: build`**.
- Compare against a recent merged PR's head SHA — it'll have all three. Wrappers-present-but-`build`-absent is the tell.
- CircleCI workflow + the `lucos/build` job both show `success` (it's not a job failure — it's a status *delivery* drop).

**Fix (SRE domain — CircleCI re-run):** re-run the `build-deploy` workflow via `POST /api/v2/workflow/{id}/rerun` `{"from_failed": false}`. **Safe on a non-main PR branch** because the orb deploy jobs are `filters: branches: only: main` — the re-run only rebuilds + re-posts the `build` status, no deploy fires. The re-delivered `build` status lands with a **~2-min lag AFTER the workflow finishes** — don't verify too early and conclude failure (I did, on PR #97 2026-06-10). Once it lands, GitHub-native auto-merge merges automatically.

**Do NOT "fix" by changing the required check to `serial-end-1`.** That's the lock-*release* job and almost certainly goes green regardless of build pass/fail → an unsafe gate that doesn't gate. Keep requiring `ci/circleci: build` (correctly reflects pass/fail) and eat the rare re-run.

First hit: lucos_router PR #97 (docs-only, closed lucos_router#95), 2026-06-10. One occurrence → accepted the risk, no config change. Revisit the required-check choice only if it recurs frequently. Related: [[pattern_dependabot_blocked_by_required_approval]] (other "green PR won't merge" gate mismatch).
