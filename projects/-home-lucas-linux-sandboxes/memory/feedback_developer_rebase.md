---
name: Developer rebase issues
description: lucos-developer struggles with rebasing — may need explicit instructions or a different approach
type: feedback
---

lucos-developer doesn't reliably know how to rebase branches. When a rebase is needed, consider either giving very explicit step-by-step instructions, or asking a different teammate (e.g. sysadmin) to do it.

**Why:** User had to manually merge a PR because the developer's "rebase" didn't actually work, wasting time.

**How to apply:** When a developer PR needs rebasing, check the result (is the branch actually ahead of main?) before telling code reviewer to re-approve. Consider alternative approaches like merge commits if rebase proves unreliable.
