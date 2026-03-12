---
name: merge-permissions-check
description: Must verify unsupervisedAgentCode before every merge — recurring failure point
type: feedback
---

## Merge permission check is mandatory for every PR, every repo

Before calling the merge API on any PR, always check `lucos_configy/config/systems.yaml` for `unsupervisedAgentCode: true` on the target repo. This is a hard gate, not a suggestion.

**Failure history:**
- lucos_media_manager PR #152 — merged without checking (first offence, led to pr-review-loop.md being updated)
- lucos_contacts PR #538 — merged without checking (second offence)

**The pattern that fails:** checking once for the repo where the rule was first clarified, then forgetting to apply it to subsequent repos in the same or later sessions.

**The correct flow before every merge:**
1. Grep `lucos_configy/config/systems.yaml` for the repo name
2. Confirm `unsupervisedAgentCode: true` is present
3. Only then call the merge API

If `unsupervisedAgentCode: true` is absent: post a comment on the PR saying it's approved and ready for human merge, then report back to team-lead. Do not merge.
