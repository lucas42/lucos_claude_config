---
name: feedback_dependabot_stale_regression
description: Dependabot recreate is deterministic — recommending it for stale regression PRs wastes human time. Diagnose whether the PR is a net regression before suggesting any fix.
metadata:
  type: feedback
---

**Never recommend `@dependabot recreate` as a first fix for a Dependabot CI failure.** Dependabot is fully deterministic — it regenerates from the same inputs (current package.json + registry state at recreate time). If the lock file inconsistency is caused by main having moved forward (e.g. mocha was bumped to a newer version after the PR opened), recreating produces the same result.

**Why:** lucas42 confirmed this directly after I recommended recreate on lucos_media_seinn #452. The PR was stale: it had been opened when mocha@11.3.0 was in the lock file; main subsequently moved to mocha@11.7.5, which pulled in diff@7.x and workerpool@9.x. The PR's lock file resolved mocha to 11.3.0 (a regression), and `@dependabot recreate` reproduced the same regression.

**How to apply:** For any Dependabot PR with a `package-lock.json`/`package.json` sync failure, do this first:

1. Compare key transitive dep versions between the PR branch and main (`diff`, `workerpool`, `mocha`, any other suspiciously-versioned dep).
2. If the PR branch resolves any package to a LOWER version than main (a regression), the PR is stale — `@dependabot recreate` will not help.
3. Check whether the "from→to" bumps in the PR description are actually regressions vs main. If the "to" values are LOWER than main's current versions, the PR predates main's progress.
4. If the PR is a net regression with no compensating improvements, **recommend closing it**. Dependabot will open a fresh PR against the current main state when it next runs.
5. Only suggest `@dependabot recreate` when something genuinely changed since the PR was opened (e.g. a constraint was fixed in package.json, a new package version was published) — and verify the specific change first.

[[feedback_incident_report_followups]]
