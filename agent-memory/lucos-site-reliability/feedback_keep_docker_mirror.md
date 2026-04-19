---
name: Docker mirror stays, fix at source
description: lucas42 wants the docker.l42.eu mirror kept in the orb's publish-docker; removing it to dodge registry:2 digest-404 bug is not the right fix
type: feedback
---

**Rule:** Do not propose removing the `docker.l42.eu` BuildKit mirror configuration from `lucos_deploy_orb/src/commands/publish-docker.yml` as a fix for `registry:2` bugs. Keep the mirror in place; fix mirror-side issues at the mirror layer (e.g. lucas42/lucos_docker_mirror#39 for the digest-404 bug).

**Why:** Docker Hub rate-limits unauthenticated and small-account pulls. The mirror's primary purpose is avoiding those limits across estate-wide builds (multiple concurrent CI jobs pulling the same base images). Removing the mirror dodges one bug but re-exposes the estate to a worse failure mode (rate-limit lockouts that are harder to recover from and affect all repos at once). Confirmed 2026-04-19: I opened lucas42/lucos_deploy_orb#143 to remove the mirror config as the "agreed fix" for #136; lucas42 rejected it and closed #136. The fix belongs in `lucos_docker_mirror`, not `lucos_deploy_orb`.

**How to apply:**
- When triaging orb failures that trace back to the mirror, raise/update an issue on `lucas42/lucos_docker_mirror` rather than proposing orb-side removal.
- If a short-term estate unblock is genuinely needed (active outage, mirror-side fix not landing fast enough), present it as a reversible *workaround* with an explicit plan to restore the mirror after the mirror fix ships, not as the permanent fix.
- Never frame mirror removal as "just ~30 lines, simple deletion" — the cost is real and recurring in Docker Hub rate-limit exposure.
