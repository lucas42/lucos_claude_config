---
name: buildkit-oci-manifest-drift
description: lucos_deploy_orb#195 investigation — BuildKit's default single-manifest media type flipped Docker v2 -> OCI v1, estate-wide, not a #186 recurrence
metadata:
  type: project
---

**lucos_deploy_orb#195** (2026-08-28, analysis posted, Needs Analysis — investigation only, no fix chosen yet): `moby/buildkit:buildx-stable-1` is an unpinned floating tag, re-pulled fresh on every CI run with no local persistence across CircleCI's ephemeral VMs — so a routine upstream BuildKit release silently changes push behaviour for every consumer with zero commits to `lucos_deploy_orb`. Confirmed via direct before/after CI log diff (same command, same Dockerfile, six weeks apart): pushed manifest `MediaType` flipped `application/vnd.docker.distribution.manifest.v2+json` → `application/vnd.oci.image.manifest.v1+json`. Matches a documented industry-wide BuildKit/buildx default shift (moby/buildkit#5466).

**Bounding a drift window ≠ measuring it — keep "last known good" and "known broken duration" as distinct facts.** `test-publish-docker` only ran twice on `main` in the 6-week gap (2026-07-13, then 2026-08-28) — CircleCI's own build history confirms zero runs in between, so the flip happened *sometime* in that window, not "was red for 6 weeks". This is a reusable general lesson, not orb-specific — see [[feedback_verify_timeline_before_stating]].

**Not a recurrence of #186** (which was about an OCI *index* falsely claiming the build host's arch via provenance/SBOM attestation manifests — fixed by `--set "*.attest=...,disabled=true"` in `publish-docker.yml`). Confirmed both the failing orb-CI push and a real production image (`lucas42/lucos_backups:latest`) are still bare single manifests, not indices — the #186 fix is intact. What changed is only the media type of that single manifest, which is functionally just as platform-agnostic as the old Docker v2 one (neither carries a platform claim without an index). No confirmed pull/deploy failure from this — flagged as possibly-inert, not verified either way.

**This is not orb-CI-only.** `lucos/build` (`src/jobs/build.yml`) calls `publish-docker` with `platform` defaulting to `""` — same code path as the failing test. Checked `lucas42/lucos_backups:latest` (built 2026-08-28 via that default path) directly via `docker buildx imagetools inspect` and got the same OCI media type — confirms this is **already live in production publishes estate-wide**, not a cosmetic CI-only finding. Worth checking before assuming any "just fix the assertion" framing is low-stakes.

**Useful technique for this kind of investigation**: `docker buildx imagetools inspect <image>` (no auth needed for public Docker Hub images) directly reveals manifest media type and index/manifest shape without needing to pull the image — fast way to compare a "before" state (an old CI run's logged output) against "now" (live registry state).
