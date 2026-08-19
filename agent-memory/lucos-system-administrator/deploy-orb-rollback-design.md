---
name: deploy-orb-rollback-design
description: lucos_deploy_orb#192 analysis — why deploy rollback must key off the running container's image, not git tags, and why it belongs in the orb not per-service compose
metadata:
  type: project
---

**lucos_deploy_orb#192** (2026-08-19, analysis posted, recommended Ready): a failed deploy today leaves the service DOWN — `docker compose up` recreates the container before discovering the healthcheck fails, and the previous working container is already gone. Root incident: `lucos/docs/incidents/2026-08-17-backups-python-alpha-charset-normalizer.md` (15h24m outage).

**Key design insight, evidenced by the actual incident data — don't derive a rollback target from git tags, even "second-newest tag."** The 2026-08-17 tag sequence was v1.4.31 (last known-good) → v1.4.32 (broken) → v1.4.33 (broken, same defect). Asked from v1.4.33's perspective, "previous tag" resolves to v1.4.32 — itself broken. The correct signal is "the image that was actually running and healthy immediately before this deploy attempt," captured via `docker inspect --format '{{.Config.Image}}'` on the currently-running (or stopped-not-removed, for host-net services) container **before** `docker compose up` touches anything — not inferred from tag ordering.

**Fix belongs in the orb, not per-service compose.** `src/commands/deploy.yml`'s deploy step is shared by every `deploy-{avalon,xwing,salvare,virgon-express}.yml` job across all ~55 systems; repos pin the orb as a floating `lucos/deploy@0`, so an orb fix ships estate-wide with zero per-repo PRs. Compose files already conform to the `${VERSION:-latest}` templating this depends on — nothing about them needs to change.

**Separate, independent, cheaper bug in the same file:** "Determine deployed version from git tags" (`deploy.yml`) does `git tag --list 'v*' --sort=-v:refname | head -1` — globally newest tag, ignoring which commit is checked out. Breaks specifically when re-running an *old* CircleCI pipeline as an emergency rollback lever (the incident's attempted recovery — deployed v1.4.33, the broken version, instead of the old pipeline's own v1.4.31). Fix: `git tag --list 'v*' --points-at HEAD --sort=-v:refname | head -1`. Recommended as its own ticket rather than bundling with the rollback feature.

**Explicitly out of scope:** Option 2 (health-gated blue-green cutover — start new container alongside, swap on healthy) needs a second-container-plus-repoint mechanism at the `lucos_router` layer and per-service compose changes across the estate — a much bigger architectural change than a bounded retry-loop extension. Agreed with SRE's own ticket framing that it isn't worth it now; would need its own ADR if ever revisited.

**Auto-rollback must stay loud, not quiet.** Job must still `exit 1` even after a successful rollback (preserves "this version was broken" signal — must never turn the pipeline green). And it needs a distinct Loganne event on rollback, separate from the normal deploy-log event — this incident's own Stage 5/6 findings (`lucos_docker_health`'s 42 false "recoveries" during an outage that never recovered, and "detection worked, response didn't") are specifically about quiet self-healing being worse than staying visibly broken, because it removes the reason to look.

See [[configy-undeployed-system-entry-pattern]] for a similarly evidence-driven design constraint (read the actual source/data before proposing the fix, not just the surface description).
