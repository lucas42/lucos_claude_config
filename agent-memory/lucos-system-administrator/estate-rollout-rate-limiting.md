---
name: Estate rollout rate limiting
description: 5-min merge pauses caused GraphQL rate exhaustion in 2026-04-16 rollout — use 10-min pauses
type: feedback
---

Use **10-minute pauses** between merge batches during estate rollouts, not 5 minutes.

**Why:** Each merged PR triggers a CI pipeline running `semantic-release` via `calc-version`, which makes multiple GitHub GraphQL API calls. With 5-minute pauses, earlier batches' CI is still running when the next batch fires. With 35 repos, this produced 30+ concurrent `semantic-release` jobs that exhausted the 5000 point/hour GraphQL rate limit — blocking 24 service deploys for ~90 minutes. Incident: 2026-04-16-estate-rollout-rate-limit-ci-failures (lucos_deploy_orb#82).

**How to apply:** Any time the coordinator or instructions specify merge batch pauses during an estate rollout, default to 10 minutes minimum. If told 5 minutes, flag the rate limit risk and recommend 10.
