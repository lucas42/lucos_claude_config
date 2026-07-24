---
name: review-circleci-build-convention
description: lucos/build with an optional platform parameter is the current unified CircleCI build orb job — the old build-multiplatform/build-amd64/build-armv7l/build-arm64 jobs and pici host are all retired.
metadata:
  type: feedback
---

Pass `platform: "linux/amd64,linux/arm64"` only for ARM-targeted services; omit it for amd64-only. Don't flag a plain `lucos/build` (no `platform` param) as needing multiplatform migration without first confirming the service is actually deployed to an ARM host.

`docker-compose.yml` image tags should be plain (e.g. `lucas42/lucos_foo`), no `${ARCH}-latest` suffix — Docker resolves platform from the manifest automatically. No `architecture` parameter needed in CircleCI deploy jobs for new services. Confirmed current pattern via lucos_aithne PR #13; pici repo is archived.
