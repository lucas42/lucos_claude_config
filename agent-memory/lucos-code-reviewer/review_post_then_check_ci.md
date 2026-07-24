---
name: review-post-then-check-ci
description: Post the code-quality review (APPROVE/REQUEST_CHANGES) immediately, then check CI separately — waiting for CI first creates a race where a developer push lands your review on a stale, unexamined commit.
metadata:
  type: feedback
---

Post review first based on the diff you actually read, then poll CI. If CI fails afterward, post a follow-up REQUEST_CHANGES with the specific failure.

Confirmed failure: lucos_configy PR #64 — waited for CI before reviewing; developer pushed a new version while CI ran, and the review landed on a commit that was never examined.
