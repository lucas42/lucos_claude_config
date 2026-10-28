---
name: pattern-tag-push-workflows-permission
description: lucos-ci tag push "refusing to allow a GitHub App ... without `workflows` permission" fires on a commit that DOESN'T touch workflows, when a newer workflow-changing commit is already on main — self-heals; lucos_deploy_orb#210
metadata:
  type: project
---

`push-release-tag` fails with `! [remote rejected] vX (refusing to allow a GitHub App to create or update workflow \`.github/workflows/<f>\` without \`workflows\` permission)`. The tagged commit usually does **not** change any workflow file — it is an *older* commit whose tag push lands after a Dependabot `github_actions` (or workflow rollout) merge has moved main. Inferred (3 repos, not from GitHub docs): GitHub diffs a new ref against the default-branch tip. The newer workflow commit tags fine, so the repo goes green on its own pipeline and monitoring rarely alerts. 27/41 main failures 10-14→10-28. Filed lucas42/lucos_deploy_orb#210.

**Why:** easily misread as the push-throttle 403 (different message: "Permission to … denied to lucos-ci[bot]") or as "the commit touched workflows".

**How to apply:** classify a red `Push git tag` step by its exact message before re-running. WORKFLOWS-PERM needs no re-run if a newer pipeline exists; the 403-denied variant does need one (nothing else re-runs it). See [[topic_ci_infra_patterns]].
