---
name: Verify the CI build mechanism before claiming it gives you sequencing
description: Don't hand-wave inter-job ordering as "implicit in CI" — read the orb/config and confirm what actually happens
type: feedback
---

# Verify the CI build mechanism before claiming it gives you sequencing

**Rule:** When recommending a fix that depends on CI doing things in a particular order (e.g. "build A before build B" or "image A is published before image B's `FROM` line runs"), do not assert "this is already implicit in CI" without actually reading the orb / `.circleci/config.yml` to confirm. If the mechanism is parallel by default, your fix is just relocating the bug.

**Why:** On 2026-04-29, lucas42 caught me proposing `FROM lucas42/lucos_<repo>_app:latest` in a web Dockerfile as the fix for lucos_contacts#668 / lucos_eolas#212. I waved at "build-order coupling between app and nginx images. Already implicit in CI." That was hand-waving, not architecture. Had it shipped, the web build would have pulled the *previous* deploy's `app:latest` from Docker Hub, perfectly reproducing the staleness bug at a different layer. lucas42 spotted it because the ordering claim was vague enough to obviously need verification.

**How to apply:**
- Whenever a recommendation hinges on CI sequencing, registry visibility, or "the image is built before X reads it," **stop and read the actual config** before posting. Read `.circleci/config.yml` of the affected repos and the relevant orb commands (`~/sandboxes/lucos_deploy_orb/src/...`).
- The lucos orb today builds via `docker buildx bake -f docker-compose.yml <all-targets>` in a single call — so inter-image dependencies are expressed in compose (`additional_contexts: target:<name>`), not in CI workflow `requires:` blocks. See [reference_buildx_bake_additional_contexts.md](reference_buildx_bake_additional_contexts.md).
- The architectural rule generalises: any time you find yourself writing "this'll work because [some implicit ordering]", treat that as a yellow flag and verify before posting. Implicit orderings are exactly the kind of thing that's wrong silently.

This applies even when the substantive recommendation is correct. The Option A pick (drop the volume) for those issues was right; the build mechanism that backed it up was incomplete. Both halves need rigour.
