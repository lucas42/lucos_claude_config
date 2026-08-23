---
name: feedback_standalone_ping_staleness
description: A standalone "PR approved" ping needs its own fresh re-fetch — a substantive report's fetch doesn't cover it
metadata:
  type: feedback
---

A bare status-only message (e.g. "PR approved: {url}" sent right after the substantive end-of-issue report) is itself a status report and needs a re-fetch of `merged`/`state` immediately before sending it — reusing the fetch from the substantive report a message earlier is not enough.

**Why:** team-lead caught 4 instances in one session (2026-08-23) where this exact ping was sent after the PR had already merged — lag ranged from 23s to 5m37s. On an unsupervised repo, approval and merge can be seconds apart, so a check that was accurate when run can be stale by the time a follow-up message is composed. The existing rule ("never state approved without re-fetching") was being followed for the substantive report every time, but a terse one-liner didn't read as "reporting back" so it fell outside the rule's felt scope, even though the rule's text already covered it.

**How to apply:** Before any message whose content is only a PR state, re-fetch `pulls/{n}` and check `merged` right then. If it's already merged, say so as part of the report rather than sending a second message that just restates a now-stale "approved". See [[feedback_pr_completion_reporting]] for the separate rule on what NOT to say (supervision/auto-merge language) — this is about freshness, that one is about content. Consolidated into `agents/lucos-developer.md`'s existing "Never state 'PR approved'..." bullet rather than adding a parallel one.
