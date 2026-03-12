---
name: never-merge-prs
description: Agents must NEVER merge PRs — auto-merge or user handles it, not agents
type: feedback
---

## Agents must NEVER merge PRs

Do not call the merge API on any PR under any circumstances. Merging is handled by auto-merge (GitHub) or the user. This is not the agent's responsibility.

**`unsupervisedAgentCode: true` does NOT grant merge permission.** It is unrelated to whether an agent may call the merge endpoint. Do not check this flag as a gate for merging — the answer is always no.

**The correct flow after a PR is approved:**
1. Report back to team-lead with the PR URL and outcome
2. Stop — do not merge, do not wait for CI, do not poll

**Failure history:**
- lucos_media_manager PR #152 — merged without authorization
- lucos_contacts PR #538 — merged without authorization
- lucos_photos_android PR #72 — merged thinking `unsupervisedAgentCode: true` granted permission (it does not)
