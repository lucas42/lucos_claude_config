---
name: Fresh review request after new commits
description: When pushing additional commits to an open PR before the reviewer has started, send a fresh review request so they examine the full diff
type: feedback
---

When I push additional commits to an already-open PR before the reviewer has started their review, I must send a fresh review request via SendMessage — not just a "heads up" note. The message should make clear it's a new review request covering all commits.

**Why:** Auto-merge can fire before the reviewer has a chance to read the new diff if I only send a casual notification. The reviewer may then approve on a SHA they haven't fully examined. This happened on lucos_docker_health#30 — I sent a message flagging the second commit, but auto-merge ran before the reviewer read it.

**How to apply:** Any time I push to a PR branch after it's already open, follow up immediately with a SendMessage to lucos-code-reviewer that explicitly requests a re-review of the full PR (not just acknowledges the change).
