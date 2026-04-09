---
name: Merged is not deployed
description: Don't say "deployed" or "live" when a PR has just been merged — deployment is automated but takes non-zero time
type: feedback
originSessionId: e1ee345d-27ea-447a-820b-c175834e957f
---
When a PR is merged, say "merged" — not "deployed" or "live." Deployment is fully automated from merge, but it takes a non-zero amount of time to complete. Saying something is "deployed" or "live" immediately after merge is inaccurate.

**Why:** The user corrected us for saying "MCP auth is deployed" when the PR had just been merged. Automated deployment doesn't mean instant deployment.

**How to apply:** Use "merged" when a PR has been merged. Only say "deployed" or "live" if you have confirmed the deployment has completed (e.g. by checking the service's /_info endpoint or monitoring). When summarising, say "PR merged — deployment will follow automatically."
