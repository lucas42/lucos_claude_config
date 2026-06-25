---
name: aithne-signing-key-age-not-deploy-signal
description: aithne /_info signing_key_age is NOT a restart/deploy confirmation — key only rotates at startup IF already older than rotation interval; verify deploy via container StartedAt + image tag
metadata:
  type: project
---

aithne's `/_info` `active_signing_key_age_seconds` (and the `signing_key_age` check) is a "process running too long without a deploy" LIVENESS signal — **NOT** a deploy/restart confirmation signal. Do not infer "process hasn't restarted" from an old key age.

**Why:** the signing key lives in the persistent `credential_store` volume (SQLite `/data/aithne.db`), so it SURVIVES restarts. aithne's rotate-at-startup logic only fires **if the key is already older than the rotation interval**. A key under that threshold (e.g. 15.5 days when interval is longer) is legitimately left untouched across a fresh restart — and `signing_key_age` correctly reads `ok: true`. So "key resets to near-zero on restart" is false, and "old key ⇒ stale process" is a false inference.

**How to apply:** to confirm aithne (or any service) is on the latest code, check the AUTHORITATIVE signals directly: `docker inspect lucos_aithne --format '{{.State.StartedAt}} {{.Config.Image}}'` on avalon (StartedAt vs deploy time; image tag = version), cross-ref the image tag to the git tag/commit. Don't reason from key age.

**Grounding (2026-06-25):** team-lead escalated "aithne not redeploying ~43min after 4 merges" citing a ~15.5-day key age. Reality: all 5 main pipelines (360/363/366/370/373) deployed to SUCCESS, none auto-cancelled; container had StartedAt 12:56:31Z (during pipeline 373's deploy), Up 8 min, running `1.20.17` = commit `09f1d95d` (final merge). Deploy worked fine — the key age was a red herring. aithne runs on avalon; tag form for SSH is `avalon.s.l42.eu` (NOT `avalon`). Suggested (not yet filed) a `/_info` `version`/`commit` field so "is latest live?" is answerable without SSH — see [[pattern_three_stage_env_var_wiring]] context on /_info diagnostics.
