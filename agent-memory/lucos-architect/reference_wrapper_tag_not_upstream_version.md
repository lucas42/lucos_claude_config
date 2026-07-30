---
name: reference-wrapper-tag-not-upstream-version
description: For adopted third-party apps in a lucos wrapper image, our image tag says nothing about the upstream version inside — check the app's own version file
metadata:
  type: reference
---

For any **adopted third-party app wrapped in a lucos image** (pattern established by `lucos_worlds` ADR-0001), our image tag tells you **which of our builds** is running and **nothing** about which upstream version is inside it.

- Our tag (e.g. `lucas42/lucos_worlds_web:1.2.4`) comes from the `VERSION` build arg — it increments on **any** commit to the wrapper repo.
- The upstream version only changes when the Dockerfile `FROM` line moves.
- So a wrapper rebuild for an unrelated commit bumps `1.2.x` while the upstream app stays put. One wrapper tag can be consistent with several upstream versions.

**The authority is the upstream app's own version file / API.** For BookStack (linuxserver image): `docker exec <container> cat /app/www/version` → e.g. `v26.05.2`. Note the *shape* difference is itself a tell — BookStack versions are date-based (`v26.05.2`), so a semver like `1.2.4` can never be one.

Verified directly on avalon 2026-07-30: `$VERSION` = `1.2.4` while `/app/www/version` = `v26.05.2`.

**Why it matters (the trap):** verifying an upstream **security** upgrade by observing a bumped wrapper tag reports the fix as live with no evidence that it is. Raised on `lucos_worlds`#55 as an explicit post-deploy gate. Also correct a teammate if they quote the wrapper tag as the app version — it reads as a verified infra fact and propagates.

Generalises to every future adopted app, not just BookStack. See [[project-lucos-worlds]] and the declared-≠-deployed rule in my Self-Verification list.
