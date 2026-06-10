---
name: pattern-buildx-attestations-force-index-platform-claim
description: Why "platform-agnostic" data-only images publish amd64-only — buildx attestations wrap single-platform builds in a platform-claiming OCI index; orb platform:"" doesn't disable them
metadata:
  type: project
---

A `FROM scratch` data-only image (e.g. lucos_auth_scopes scopes.yaml, lukeblaney_cv) published via the lucos deploy orb's `release-docker` with `platform: ""` comes out **amd64-only**, so arm64 (or any non-amd64) `COPY --from=img@digest /file` fails: `no match for platform in manifest: not found`.

**Why:** buildx enables provenance+SBOM attestations BY DEFAULT. Attestations can't sit in a bare manifest, so buildx wraps even a single-platform build in an OCI **image index** (`application/vnd.oci.image.index.v1+json`) carrying a concrete `linux/amd64` platform descriptor + an `unknown/unknown` attestation-manifest. An **index is STRICTLY platform-matched** at `COPY --from`/pull → non-listed arch fails. A plain **v2 manifest** (`application/vnd.docker.distribution.manifest.v2+json`) is **leniently consumable from ANY arch** (verified amd64/arm64/s390x/riscv64/ppc64le all pull an amd64-built plain manifest).

**Key distinction — index vs plain manifest, NOT content arch.** "Platform-agnostic content" is irrelevant to manifest resolution; only the artefact TYPE matters. Multi-arch (`amd64,arm64`) index only matches the arches you enumerate — still fails on s390x/riscv64. So multi-arch ≠ genuinely agnostic; a plain manifest is.

**Fix is in the ORB, not the repo** (lucas42/lucos_deploy_orb#186): in `publish-docker.yml`, when `platform` is empty add to the bake args `--set "*.attest=type=provenance,disabled=true" --set "*.attest=type=sbom,disabled=true"` (or `buildx bake --provenance=false --sbom=false`) → emits a plain manifest. Verified through the orb's real `buildx bake` path. The orb's `platform: ""` doc PROMISES "no platform manifest claim" but doesn't deliver it — doc intent is sound, orb just doesn't honour it. Don't "fix" by deleting the `platform: ""` guidance or switching to multi-arch.

**Diagnostic:** `docker buildx imagetools inspect <img>` — if it's an index with `unknown/unknown` attestation-manifest + one platform, that's the bug. Reproduce cross-arch failure with a throwaway `FROM scratch` + `COPY --from=<img> /f` built `--platform linux/arm64`.

lucas42 (2026-06-10): wants data-only images GENUINELY platform-agnostic (any arch), not multi-arch. lukeblaney_cv is NOT deployed — it's a `COPY --from` consumer pulled by lukeblaney_co_uk, so it's a 2nd instance of this exact bug. After orb ships, both keep `platform: ""`, rebuild, consumers (aithne, lukeblaney_co_uk) re-pin to new plain-manifest digest. Sandbox host is arm64 — to build a true amd64-only artefact for testing you must force `--platform linux/amd64`.
