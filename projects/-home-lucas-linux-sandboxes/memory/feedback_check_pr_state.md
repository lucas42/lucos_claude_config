---
name: Check PR state before reporting
description: Always query GitHub for PR/issue state before presenting summaries — never rely on conversation memory
type: feedback
originSessionId: e1ee345d-27ea-447a-820b-c175834e957f
---
Always check GitHub API for actual PR/issue state before presenting status summaries to the user. Do not rely on conversation memory for open/merged/approved state — things change between turns (user approves PRs, CI merges them, etc.).

**Why:** The user corrected us twice: (1) giving a status table based on conversation memory that was already stale, and (2) reporting a PR as "awaiting approval" when lucas42 had already approved it and it was just waiting for CI/auto-merge. These are different states and must be distinguished.

**How to apply:** Before any status report that lists PR or issue states, query GitHub for the current state of each item — including reviews. Distinguish between "awaiting approval" (no approval from lucas42), "approved, awaiting CI/merge" (approved but not yet merged), and "merged". This applies to summary tables, status updates, and any claim about whether a PR is open/merged/awaiting review.
