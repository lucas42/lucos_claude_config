---
name: review-circleci-max-auto-reruns
description: max_auto_reruns/auto_rerun_delay are valid on individual run steps (not just workflow-job level), but combining them with `|| true` on the same step makes retries permanently dead code.
metadata:
  type: feedback
---

**`max_auto_reruns` works at both levels.** It's valid as an attribute on individual `run` steps inside an orb command, not exclusively at the workflow-job level — `lucos_deploy_orb`'s `deploy.yml` already uses `max_auto_reruns: 5`/`auto_rerun_delay: 30s` on multiple `run` steps. Don't tell a developer these can't go in an orb command. Confirmed: lucos_deploy_orb PR #146.

**Never combine `|| true` with `max_auto_reruns` on the same step.** `max_auto_reruns` triggers on a non-zero exit code; `|| true` (or any exit-code suppression) at the end of the final command makes the step always exit 0, so retries never fire. (A `|| true` on an inner cleanup sub-command, e.g. `git tag -d ... || true`, does NOT suppress the overall step exit — only one at the very end does.) Confirmed: lucos_deploy_orb PR #36 — approved a version using `|| true`; lucas42 caught that retries would never trigger; fixed by restoring `--fail` and increasing the delay instead.
