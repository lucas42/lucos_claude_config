---
name: dont-file-on-behalf-of-other-agents
description: Don't file GitHub issues, PRs, or other identity-bearing artifacts under your own bot account when another persona is the appropriate identity-of-record, even if their filing path is blocked
metadata:
  type: feedback
---

When another agent has been asked to file something (an issue, PR, comment) and their attempt fails — for example because their `gh-as-agent` returns 404, or their identity is misconfigured — **do not file it under your own identity** as a workaround, even if you label the body with attribution. Identity-of-record matters on GitHub artifacts; the author shown by the API is the only attribution most readers will see.

**Why:** lucas42 explicitly said *"Don't file tickets on behalf of lucos-architect. I want it clear who is creating each one."* on 2026-05-14. He values being able to see who actually created each artifact, not just who authored its text.

**How to apply:**

- When another agent can't file, **diagnose and unblock them** instead. The 2026-05-14 case was a simple `api ` prefix bug — `gh-as-agent` already runs `gh api`, so prepending another `api` makes the path become `api repos/...` which 404s. Many of these unblocking fixes are cheap once surfaced.
- If the unblock isn't immediately possible, **report the blocker back to the user** and ask how to proceed, rather than working around it under your own identity.
- Body-text attribution is *not* sufficient. Readers see the author field, not the body framing.
- This applies symmetrically: don't accept another agent filing on *your* behalf either; if your filing is blocked, fix the block.

**Related discipline:** the architect's "don't silently work around a hard tool error" rule (from `CLAUDE.md`) is the upstream version of the same principle — surface the structural problem rather than patching around it.
