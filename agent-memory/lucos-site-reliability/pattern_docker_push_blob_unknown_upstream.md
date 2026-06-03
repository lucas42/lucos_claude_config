---
name: docker-push-blob-unknown-upstream
description: "'blob unknown to registry' on docker push is upstream Docker Hub transient, NOT our code; clears on rerun; fix is push-step retry in the orb
metadata:
  type: project
---

**Signature:** CircleCI `lucos/build` job fails; `test` passes. Build log shows every compile/`COPY`/release/stage step succeeding, then dies at `exporting to image → pushing layers`:

```
ERROR: failed to solve: failed to push lucas42/<repo>:<tag>: errors:
unknown: blob unknown to registry - sha256:...
```

**This is UPSTREAM (Docker Hub), not our code.** Determination recipe:
- Build *compiles/releases cleanly* — failure is purely in the push/export phase. → not a Dockerfile/code defect.
- Same error across multiple unrelated commits/PRs in a short window. → not commit-specific.
- **Rerun with identical code goes green.** → transient, definitionally not a deterministic code bug. (Strongest single proof.)
- Docker Hub status page (dockerstatus.com) typically shows "all operational" — this flakiness is below the incident threshold, so a green status page does NOT rule out upstream. `blob unknown to registry` on push is a known Hub blob-existence race: BuildKit concludes a layer already exists upstream, skips re-uploading, then the manifest references a blob Hub doesn't actually have.
- The `docker.l42.eu` mirror is NOT implicated: it's pull-through only; pushes go to `registry-1.docker.io` directly. Mirror /v2/ returning HTTP 401 = healthy auth challenge, not an error. (And don't propose removing the mirror — see [[feedback_keep_docker_mirror]].)

**Immediate fix:** rerun the failed workflow. CircleCI reruns are in SRE's domain (PAT in lucos_agent/.env, `CIRCLECI_API_TOKEN`): `POST /api/v2/workflow/{id}/rerun` body `{"from_failed": true}`. On a PR branch the workflow is build-only (no deploy); on main, rerun also completes the deploy the push-failure aborted.

**Durable fix:** the orb's `Docker Build & Push` step (`lucos_deploy_orb/src/commands/publish-docker.yml`, `docker buildx bake --push`) has NO retry, though the adjacent `Docker Login (mirror)` step does (`max_auto_reruns: 2`). Add a bounded retry scoped to transient push errors (`blob unknown to registry`, `manifest blob unknown`, `error reading from server`, `EOF`). Tracked: **lucas42/lucos_deploy_orb#182** (filed 2026-06-03; benefits all repos, fix on the orb not the surfacing repo). Build also pushes a manifest list + attestation manifests, which widen the consistency window — trimming provenance/attestations is a secondary mitigation.

First hit hard on lucos_monitoring 2026-06-03 (#273, #274, main 3cde738 — all cleared on rerun).
