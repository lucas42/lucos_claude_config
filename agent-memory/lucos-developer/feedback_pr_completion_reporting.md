---
name: Reporting PR completion: unsupervised vs non-unsupervised repos
description: Always run check-unsupervised before reporting PR outcome; use different language depending on repo type
type: feedback
---

Always run `~/sandboxes/lucos_agent/check-unsupervised <repo-name>` before reporting PR completion. Do not rely on the code-reviewer's language — they may say "auto-merge triggered/succeeded" regardless of repo type.

- **Unsupervised repos** (`unsupervisedAgentCode = YES`): code-reviewer approval alone triggers auto-merge. Report: "PR approved and auto-merging."
- **Non-unsupervised repos** (`unsupervisedAgentCode = NO`): lucas42's approval is also required before the PR can merge. Report: "PR approved by the code-reviewer and awaiting lucas42's approval."

**Why:** Twice reported "auto-merge" on non-unsupervised repos (lucos_monitoring#133, lucos_media_manager#194) by trusting the code-reviewer's language without checking. The code-reviewer's "auto-merge succeeded" message reflects their perspective, not necessarily the actual merge outcome.

**How to apply:** After receiving code-reviewer approval, run `check-unsupervised` for the repo, then use the correct language in the report back to team-lead. Exit code 0 = unsupervised, 1 = not unsupervised.
