---
name: estate-rollout-rate-limiting
description: 2026-04-16 rate-limit incident resolved by serial groups + calc-version rewrite — no merge staggering needed
metadata:
  type: feedback
---

**No merge staggering required between estate rollout batches.** PRs can be merged as quickly as CI allows.

**Why the old rule existed:** The 2026-04-16 incident (lucos_deploy_orb#82) showed that 5-minute pauses between merge batches caused 30+ concurrent `semantic-release` jobs to exhaust the 5000 point/hour GitHub GraphQL rate limit, blocking 24 service deploys for ~90 minutes.

**Why it no longer applies:**
1. `serial-group: deploy-avalon` in each repo's CircleCI config (rolled out 2026-04-22) serializes all deploys to a given host — concurrent deploys queue in CircleCI rather than racing on the host.
2. `calc-version` was rewritten to use `git tag --list` locally — **zero** GitHub API calls. It is not `semantic-release`.

**How to apply:** Do not add inter-batch pauses for rate-limit reasons. Batching is still reasonable for observability on very large rollouts (easier to attribute failures), but there is no technical minimum wait between batches.

**What to watch for:** If the `serial-group` config or `calc-version` implementation changes in `lucos_deploy_orb`, reassess this.
