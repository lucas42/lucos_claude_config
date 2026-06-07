---
name: deploy-orb-pull-profile-blind
description: deploy-avalon exit 18 "pull access denied for *_test" = orb pull step was profile-blind; FIXED in orb 0.0.185 (2026-06-07)
metadata:
  type: project
---

**Symptom:** `lucos/deploy-<host>` job fails at step **"Pull container(s) onto remote box"** with `exit status 18` and `pull access denied for lucas42/<repo>_<service>, repository does not exist` — while `test` and `lucos/build` jobs are green. Production stays UP (pull runs *before* `compose up`, so the old container keeps serving — this is a P2 blocked deploy, not an outage).

**Cause:** the deploy orb had an asymmetry — the **publish** step (`publish-docker.yml`) enumerated services via `docker compose config` (profile-aware, so profiled services were never pushed), but the **pull** step (`deploy.yml`) used `yq '.services | keys'` over the raw YAML (profile-**blind**) and pulled each by name. Naming a profiled service explicitly bypasses the profile gate, so the deploy tried to pull a deliberately-unpublished image (e.g. a `test` service backed by a separate multi-stage `test` build target with dev-only deps).

**Trigger:** any repo adding a profiled service whose image is intentionally not published. First hit `lucos_eolas` after PR #297 (loganne-v2 + multi-stage Dockerfile `FROM app AS test`). Reference good pattern: `lucos_contacts` avoided it only because its `test` service reuses the published `app` image (`target: app`, `image: ...app`).

**Fix:** lucos_deploy_orb#184 — pull step now enumerates via `docker compose config --services` (profile-aware), matching publish. Shipped in **`lucos/deploy@0.0.185`** (merged + published 2026-06-07 13:46Z). `lucos/deploy@0` resolves to it on next compile. If this symptom recurs on a repo whose orb pin predates 0.0.185, the fix just hasn't been recompiled yet.

**Gotcha — re-running won't pick up an orb fix:** re-running a *failed* CircleCI workflow reuses the pipeline's already-compiled config (orb versions resolve at pipeline-creation time). To pick up a new orb version you must trigger a **fresh pipeline**: `POST /api/v2/project/gh/lucas42/<repo>/pipeline -d '{"branch":"main"}'`. Used this to verify the eolas fix.
