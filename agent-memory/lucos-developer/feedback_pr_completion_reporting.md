---
name: Reporting PR completion: unsupervised vs non-unsupervised repos
description: Use different language when reporting PR completion depending on whether the repo is unsupervised
type: feedback
---

When reporting that a PR is complete, distinguish between repo types:

- **Unsupervised repos** (`unsupervisedAgentCode = YES`): code-reviewer approval alone triggers auto-merge. Report: "PR approved and auto-merging."
- **Non-unsupervised repos**: code-reviewer approval is not sufficient — lucas42 must also approve before the PR can merge. Report: "PR approved by the code-reviewer and awaiting lucas42's approval."

**Why:** Saying "auto-merging" on a non-unsupervised repo was inaccurate — the PR was still blocked on lucas42's review. Learned from lucos_monitoring#133 (2026-04-07).

**How to apply:** Before reporting completion, check whether the repo is unsupervised. If unsure, use the conservative language ("awaiting lucas42's approval").
