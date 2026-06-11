---
name: pattern-homehost-deploy-pull-slowness
description: Slow-but-progressing deploy to xwing-v4/salvare = home-ISP-bound image pull, not a stall
metadata:
  type: project
---

A CircleCI deploy that looks "stalled" for a service hosted on **xwing-v4 or salvare** (the home-ISP-connected hosts) is usually just the **"Pull container(s) onto remote box" step** being bandwidth-bound, NOT hung.

**Why:** these hosts pull freshly-rebuilt images over a domestic uplink. A large/new base-image rebuild (e.g. the python:3.14 prerelease Dependabot rollout, lucos_repos#418) means new layers to transfer → the pull step alone can take ~7 min. avalon-hosted services don't have this (datacentre uplink).

**How to apply (deploy-stuck triage):**
- Get the workflow → jobs → the deploy job's v1.1 step list (`/api/v1.1/project/github/lucas42/<repo>/<jobnum>`). If every step succeeded in sequence and the current one is "Pull container(s) onto remote box" or "Deploy using docker compose", it's progressing — let it run.
- Real stall signal: a single step sitting with no progress past ~15 min.
- Verify completion via the `deploySystem` Loganne event + monitoring `/api/status`, not on-host (see SSH note below).
- Don't file a ticket for the slowness — inherent home-host bandwidth on a one-off rebuild; no cheap fix (mirror doesn't help host-side pulls; image-slimming is a per-repo Dockerfile call).

Confirmed 2026-06-11: lucos_media_import pipeline #450 (v1.0.42), reported as "possibly stalled", was a ~18min deploy (~10min build + ~7min pull to xwing-v4) that completed clean.

**Throughput baseline (xwing-v4 pull, for "is the link degrading?" questions):** ~1.25–1.5 MB/s (~10–12 Mbps), stable across 06-05→06-11. To assess deterioration, compute MB/s, NOT duration — duration conflates link speed with image size. Get image MB + pull seconds from the "Pull container(s)" step v1.1 log (`X MB / Y MB` denominators + `Pulled <N>s`). The KEY test: if the *latest* pull's MB/s is the lowest in the series → real degradation; if newest is fine and only duration grew → it's image size. 2026-06-11 worked example: duration "doubled" but newest pull was the FASTEST (1.51 MB/s) — cause was python:3.14 tripling the image (227MB→624MB), not connectivity. Run-to-run jitter of ~1.8× within a morning (0.84–1.51 MB/s) is normal household-contention noise on the home link, not a trend.

**python:3.14 rollout side-effect:** the prerelease base step-changed media_import's image 227MB→624MB (~2.75×). One-time jump (not worsening), but every migrated repo will pull ~3× more + carry a bigger footprint on xwing/salvare. If it's the full Debian python image not `-slim`, a variant switch reclaims most of it (per-repo Dockerfile call, rollout owner's decision). Disk-headroom on home hosts = sysadmin's watch.

**ROOT CAUSE of that jump (2026-06-11, proven via build-log digests):** Dockerfile is bare `FROM python:3.14` (no `-slim`). The `python:3.14` tag was REPUBLISHED on Docker Hub between two builds 3h apart — #447 07:12 pulled `@sha256:f75eeaee…` (238MB final image), #450 10:06 pulled `@sha256:4b45aa26…` (624MB) — almost certainly the 3.14 GA rebuild replacing a leaner RC. The dependabot.yml-only PR #169 merge that triggered #450 was NOT the cause (it changed nothing image-related); it just happened to rebuild right after the upstream repoint. Lesson: a bare moving base tag makes image size/contents non-reproducible (depends on *when* you built). To diagnose "image suddenly tripled": diff `FROM …@sha256:` across the two builds' `lucos/build` job logs — different digest on the same tag = upstream repoint, not a repo change. Levers: `-slim` variant (size) or digest pin (reproducibility, but fights a dependabot version-rollout).

**Reaching xwing from the sandbox (CORRECTED 2026-06-11):** direct `ssh xwing-v4.s.l42.eu` from the lucos_agent sandbox is blocked — **the sandbox itself runs ON xwing and egresses via xwing's own public IP**, so SSH to xwing's public IP loops back and is refused (`Not allowed at this time`). This is NOT a known_hosts/host-key gap (my earlier diagnosis was wrong). Fix: **route via avalon as a jump host** (ProxyJump) — sysadmin confirmed this works. To reach salvare, jump via xwing (LAN). avalon is reachable directly as `avalon.s.l42.eu`. For quick verification without SSH, CircleCI + Loganne + monitoring still suffice.
