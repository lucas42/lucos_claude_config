---
name: Reporting PR completion: unsupervised vs non-unsupervised repos
description: Always run check-unsupervised before reporting PR outcome; use different language depending on repo type
type: feedback
---

Always run `~/sandboxes/lucos_agent/check-unsupervised <repo-name>` before reporting PR completion. Do not rely on the code-reviewer's language — they may say "auto-merge triggered/succeeded" regardless of repo type.

- **Unsupervised repos** (`unsupervisedAgentCode = YES`): code-reviewer approval alone triggers auto-merge. Report: "PR approved and auto-merging."
- **Non-unsupervised repos** (`unsupervisedAgentCode = NO`): lucas42's approval is also required before the PR can merge. Report: "PR approved by the code-reviewer and awaiting lucas42's approval."

**Why:** Three incidents of wrong reporting: lucos_monitoring#133 and lucos_media_manager#194 (reported "auto-merge" on non-unsupervised repos), and lucos_arachne#350/#353 (reported "awaiting lucas42" on an unsupervised repo). The pattern is the same both ways — assuming rather than checking. **Never assume in either direction.**

**How to apply:** After receiving code-reviewer approval, immediately run `check-unsupervised` for the repo before composing the report. No exceptions. Exit code 0 = unsupervised (auto-merge handles it), 1 = not unsupervised (awaiting lucas42), 2 = treat as 1.
