---
name: Fresh review request after new commits
description: Always route through lucos-code-reviewer before re-requesting the original reviewer when addressing CHANGES_REQUESTED feedback
type: feedback
---

When addressing CHANGES_REQUESTED feedback (from lucas42 or anyone else), the sequence is always: **push fix → SendMessage lucos-code-reviewer → wait for their approval → only then re-request the original reviewer via the API**.

Never skip lucos-code-reviewer and go straight to re-requesting lucas42 after pushing a fix. This happened on lucos_search_component PR #179: lucas42 requested changes, I pushed the fix and immediately re-requested lucas42 without going back through lucos-code-reviewer first.

**Why:** Code-reviewer catches issues before lucas42 sees them. Also, when auto-merge is wired, an approved-then-CHANGES_REQUESTED-then-re-approved PR can merge without the original reviewer having confirmed the fix.

**How to apply:** Every time I push after a CHANGES_REQUESTED review, the very next action is SendMessage to lucos-code-reviewer — before calling the requested_reviewers API for anyone else.
