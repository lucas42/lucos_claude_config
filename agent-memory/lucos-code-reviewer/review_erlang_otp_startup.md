---
name: review-erlang-otp-startup
description: Erlang OTP startup reviews — check .app.src applications list and graceful-failure test coverage against ALL production failure preconditions
metadata:
  type: feedback
---

When reviewing a PR that adds new external calls (HTTP via httpc, database, etc.) to an Erlang OTP application's startup path:

**1. Check `.app.src` `applications:` list against what the new code requires.**
`inets` and `ssl` are required by any module that calls `httpc:request`. If they aren't in `applications:`, they depend on a lazy `application:ensure_all_started/1` call elsewhere. That creates an invisible call-ordering constraint — anything placed before that callsite will crash if it tries to use httpc.
- Pattern: fetch `src/*.app.src` and check `{applications, [...]}`. If new code calls `httpc:request` and `inets`/`ssl` are absent from the list, flag it.
- The safe fix is to add them to `applications:` so OTP starts them automatically before `start/2` is called.

**2. For graceful-failure tests, enumerate ALL production failure preconditions — not just the convenient one.**
When a test validates that a new function "fails gracefully", check what production failure modes actually exist:
- LOGANNE_ENDPOINT unset → short-circuits before httpc is touched (convenient, easy to test, but never hit in production)
- Endpoint set, inets not started → httpc crashes with `exit(noproc)` (production failure mode, harder to test)
- Endpoint set, inets running, network error → `{error, Reason}` return

A test that only covers the first mode gives false confidence. Ask: "Does this test exercise the same code path that production will hit?"

**Why:** lucos_monitoring PR #255 — approved `notify_startup_no_endpoint_test` which only covered the unset-endpoint short-circuit. Production had LOGANNE_ENDPOINT set and inets not started. The crash propagated through an unguarded `case httpc:request` clause, was caught by the outer `try/catch`, returned `ok` from `logger:emergency`, and OTP's `application_master` rejected `{bad_return, ok}`. Resulted in a 34-minute monitoring outage. Fix: PR #257 adds the inets-not-started test case and moves inets/ssl start before the notify_startup call.

**How to apply:** On any PR adding a new Erlang function that makes HTTP calls, (a) check .app.src for inets/ssl, and (b) read the test and ask what failure modes it doesn't cover — specifically whether the test exercises the same code path as production.
