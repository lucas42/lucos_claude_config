---
name: pattern-docker-pause-reports-unhealthy
description: `docker pause` makes Health.Status read "unhealthy" (FailingStreak 0) instantly AND for one full healthcheck interval after unpause — anything that pauses containers trips health monitors
metadata:
  type: project
---

**Docker reports a paused container's health as `unhealthy` from the instant it's paused, and it stays `unhealthy` after unpause until the next healthcheck probe runs, i.e. one full healthcheck interval.** `FailingStreak` stays **0** throughout. It's a synthetic status, not earned by failed probes. Reproduced on avalon (Docker 29.3.0) and locally (29.2.1): 10,096ms / 10,061ms after unpause at a 10s interval, ~1.2s at 1s.

**Why it matters:** lucos_docker_health reports any `unhealthy` with no error threshold, polling every 60s. So a ~1s pause reads as pause + interval of "unhealthy". `lucos_media_metadata_api_exporter` has a **60s** interval, which makes a false alert near-certain. Found while implementing lucas42/lucos_backups#344 (quiesce). It falsified the design's "the freeze stays under monitoring thresholds" claim, which even the architect's ratification hadn't caught. Tracked as lucas42/lucos_docker_health#117.

**Discriminator:** genuine `unhealthy` requires `FailingStreak ≥ Retries` (≥1). A successful probe resets the streak *and* sets healthy. So `unhealthy` + streak 0 means synthetic (pause/unpause lag).

**⚠️ Two-sided:** that synthetic status is today docker_health's ONLY signal for a container left stuck paused. Ignoring it alone removes the backstop, so it must be paired with an explicit stuck-paused check (the #117 design).

**How to apply:** before proposing anything that pauses containers (backups, maintenance, debugging), read the writers' `.Config.Healthcheck.Interval` and budget pause + interval of `unhealthy`. When a rig shows a short pause is harmless, check the health *status*, not just the pause duration. My rig timed the freeze perfectly and still missed this until I checked docker_health's source.
