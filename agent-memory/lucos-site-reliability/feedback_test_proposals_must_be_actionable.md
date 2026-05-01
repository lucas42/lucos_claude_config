---
name: Test follow-ups must be deterministic and actionable
description: Don't propose CI tests as incident follow-ups when they'd be non-deterministic or when a failure wouldn't lead to actionable work on our side
type: feedback
---

When proposing a CI / integration test as an incident follow-up, two questions must answer "yes" before filing the issue:

1. **Is the test deterministic?** A test that passes on Monday and fails on Wednesday is frustrating to live with — every flaky failure makes the team trust the test less, and eventually it gets disabled or ignored. Date-walking, time-of-day-walking, calendar-walking, locale-walking tests are all suspect for this reason.
2. **Would a failure lead to actionable work on our side?** If the code path being tested lives in a third-party library we don't own, what would we do with a test failure? "File a bug upstream and pin the version" is sometimes a real answer, but more often the failure mode is "the test is right, the library is broken, and there's nothing for us to fix" — at which point the test is just an alarm clock telling us nothing we can act on.

**Why:** lucas42 closed `lucas42/lucos_time#252` (my proposed integration test exercising every `temporal_id`-populated calendar against the current date) as `not_planned` on 2026-05-01, with both objections:

> I'd prefer we avoid non-deterministic tests. A test suite which fails on some days and not others will be very frustrating to deal with.
>
> Also, if we find a failure, what are we going to do about it? The logic we'd be testing in this case is from the temporal polyfill library. So any fixes need to go in there.
>
> I don't see any value in this sort of integration test.

Both objections were sound. I'd framed #252 as "open for discussion" partly because I sensed the cost-benefit was iffy — but the right move was not to file it at all, and instead to note in the incident report's analysis section that the bug class only gets fixed upstream and the try/catch hardening is the entire defence we control.

**How to apply:**

- For a test follow-up, write down the answers to both questions in the issue body before opening it. If either answer is "no" or "depends", strongly reconsider whether the test should exist.
- If the test would test a library / external system we don't own, the bar gets higher — the value has to come from "this would catch something the library's own tests miss AND a fix would follow on our side", e.g. via version pin, configuration change, or a workaround in our wrapping code.
- The incident report's Analysis section is a good home for "this bug class can only be fixed upstream; here's what we did to harden against the impact" framing — that captures the lesson without filing a follow-up.

**Relationship to other calibration rules:** this is sister to `feedback_calibrate_runtime_check_proposals.md` (which covers runtime monitoring checks) and to the persona's "Calibrating Follow-up Issue Proposals" section. Where that section says "build-time CI assertions are often cheap and effective" — true, but only when (1) and (2) above also hold. Don't read that line as universal endorsement of CI assertions.
