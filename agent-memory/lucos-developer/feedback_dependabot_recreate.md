---
name: feedback-dependabot-recreate
description: @dependabot recreate command requires push access — GitHub Apps cannot use it
metadata:
  type: feedback
---

`@dependabot recreate` (and other Dependabot commands) requires **push access** to the repo. GitHub Apps (including `lucos-developer[bot]`) don't have the push access that Dependabot commands require, so the comment lands but has no effect.

**Why:** GitHub's Dependabot command auth checks user push access, not GitHub App installation permissions.

**How to apply:** When a stale/broken Dependabot PR needs to be recreated: close the PR (which I can do), but do NOT comment `@dependabot recreate` — flag to team-lead that lucas42 needs to post it manually, or wait for Dependabot's next scheduled run.
