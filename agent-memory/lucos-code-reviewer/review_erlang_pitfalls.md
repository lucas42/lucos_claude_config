---
name: review-erlang-pitfalls
description: lists:join/2 returns a nested iolist not a flat string — breaks ++ concatenation and string comparisons; use string:join/2 instead, and watch re:replace/4 similarly.
metadata:
  type: feedback
---

**`lists:join/2`** (OTP 22+) returns a nested iolist, NOT a flat string. Using it with `++` string concatenation produces a nested char list that fails string comparisons and pattern matching. **`string:join/2`** returns a proper flat string — use it when the result will be concatenated with `++` or compared as a string. Similarly, `re:replace/4` with `{return, list}` can return an iolist — wrap with `lists:flatten/1` before using with `++`.

Confirmed as a real CI failure in lucos_monitoring PR #58. For the related OTP-startup ordering pitfall (`.app.src` `applications:` list vs lazy `httpc`/`ssl`/`inets` starts), see [[review-erlang-otp-startup]].
