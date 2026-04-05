---
name: Auto-commit and push ~/.claude changes
description: Don't ask before committing and pushing changes to the ~/.claude (lucos_claude_config) repo
type: feedback
---

Commit and push changes to `~/.claude` (lucos_claude_config) without asking. Just do them.

**Why:** The user considers this repo low-risk — it's agent configuration, not application code. Asking for permission each time slows things down unnecessarily.

**How to apply:** After making edits to files in `~/.claude`, commit and push to main directly. No confirmation needed.
