---
name: no-mental-pr-queue
description: Don't maintain a mental PR review queue — check GitHub for PR state instead of assuming from memory
type: feedback
---

Don't keep a running list of "PRs waiting for your review" based on what's happened in the conversation. The user won't tell you every time they merge a PR, so the list goes stale immediately.

**Why:** GitHub is the source of truth for PR state, not conversation memory. Presenting an out-of-date queue is noise.

**How to apply:** Only mention PRs if they're still open on GitHub AND they're blocking the next piece of work. If you need to know whether a PR is merged, check GitHub rather than assuming from conversation context.
