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

**SSH gap:** `ssh xwing-v4.s.l42.eu` fails host-key verification from the lucos_agent sandbox (known_hosts entry missing — avalon works via the documented `avalon.s.l42.eu`). Fall back to CircleCI + Loganne + monitoring for verification. TODO: add xwing-v4 (and check salvare) known_hosts entry so on-host diagnostics work.
