---
name: lucos_deploy_orb supervised status
description: lucos_deploy_orb requires lucas42's manual approval to merge — do not report it as auto-merge/unsupervised
type: feedback
---

`lucos_deploy_orb` is a supervised repo (`unsupervisedAgentCode = NO`). PRs require lucas42 to review and approve manually — auto-merge does not trigger.

**Why:** Incorrectly reported PR #115 as "auto-merge should trigger" after the code-reviewer stated it was unsupervised. The reviewer was wrong; always verify supervision status independently.

**How to apply:** When reporting PR completion for lucos_deploy_orb, always say "supervised repo, needs lucas42 to merge" — same as other supervised repos like lucos_photos.
