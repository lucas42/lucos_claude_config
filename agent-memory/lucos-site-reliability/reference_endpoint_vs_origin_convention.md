---
name: reference-endpoint-vs-origin-convention
description: lucos env-var naming convention — `_ENDPOINT` holds full URL with path, `_ORIGIN` holds origin only; documented in lucas42/lucos#148
metadata:
  type: reference
---

Per lucos convention, env vars must be named to match the shape of their value:

- **`*_ENDPOINT`** — full URL including path (e.g. `https://schedule-tracker.l42.eu/jobs`).
- **`*_ORIGIN`** — origin only, no path (e.g. `https://schedule-tracker.l42.eu`).

Documented in [`lucas42/lucos#148`](https://github.com/lucas42/lucos/pull/148) (merged 2026-05-13T22:34:02Z, title: "Document *_ENDPOINT vs *_ORIGIN env-var naming convention").

When reviewing or writing code that reads such a variable: if you see a `*_ENDPOINT`-named variable being concatenated with a hard-coded path (e.g. `os:getenv("X_ENDPOINT") ++ "/jobs"`), that's a convention violation. Either rename to `*_ORIGIN` or move the path into the cred value.

Surfaced as a latent bug in [pattern-three-stage-env-var-wiring](pattern_three_stage_env_var_wiring.md) — see the 2026-05-13 scheduled-jobs blackout incident at `lucos/docs/incidents/2026-05-13-scheduled-jobs-monitoring-blackout.md`.
