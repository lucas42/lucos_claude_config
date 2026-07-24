---
name: feedback-be-assertive-request-changes
description: Concrete fixable issues (implicit ordering dependencies, missing idempotent calls, a missing applications:/inets/ssl entry) go in REQUEST_CHANGES, not as a parenthetical note in an approval — notes get missed.
metadata:
  type: feedback
---

Reserve approval-with-notes for genuinely subjective points or things needing real design discussion. A note buried in an APPROVE is easy to miss and may never get fixed; REQUEST_CHANGES forces the author to address it before merge.

Confirmed: lucos_monitoring PR #93 — an `ssl`/`inets` OTP-application-startup ordering dependency in `fetcher_circleci` was noted but not blocked on; lucas42 confirmed it should have been REQUEST_CHANGES. See [[review-erlang-otp-startup]] for the underlying `.app.src` check this class of bug requires.
