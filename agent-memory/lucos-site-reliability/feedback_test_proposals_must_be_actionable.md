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

**Relationship to other calibration rules:** this is sister to `feedback_calibrate_runtime_check_proposals.md` (which covers runtime monitoring checks) and to the persona's "Calibrating Scope and Follow-up Proposals" section. Where that section says "build-time CI assertions are often cheap and effective" — true, but only when (1) and (2) above also hold. Don't read that line as universal endorsement of CI assertions.

## A rule phrased as "do X carefully" is satisfied by someone who did X carefully

**2026-08-09, lucas42/lucos#288** — two proposed rules in a row were defeated by the *same* four instances, both because they were procedural:

- **A numeric bar** ("`/_info` generates in <0.5s", or "O(1) in the working set"). Tested against all four instances: neither number catches more than one, and they catch **different** ones. A reviewer holding either passes two live violators *while believing they have checked*.
- **My own "no unbounded duration" clause.** `lucos_media_weightings` **did** bound it — `UPSTREAM_TIMEOUT_SECONDS = 1.0`, both probes via `ThreadPoolExecutor(max_workers=2)` so cost is `max` not `sum`, and the docstring shows 1.0s was deliberately raised *from* 0.5s after false positives. A careful implementation that thought about exactly this, and still failed, because a bounded 1.0s probe inside a 1.0s poll budget leaves nothing for the response.

**Why:** a procedural rule describes an action, so it is satisfied by performing the action. The defect survives. **What worked instead: an outcome + a reviewer test.** *"`/_info` must fail only when the service itself is failing"*, applied via *"if this service were completely healthy, could this endpoint still fail or exceed its budget?"* — four for four, and applicable to a diff without tracing every path.

**How to apply:** when drafting or reviewing any convention, ask **"could a conscientious author satisfy this wording and still ship the defect?"** If yes, it is procedural — restate it as the outcome you actually want, and attach a test a reviewer can run against a diff. Watch for the pull back toward the procedural form: it reads more actionable, which is exactly why it gets chosen. Two related traps seen the same day: a rule must also **ship green** (a convention red on day one trains everyone to ignore it — lucas42/lucos#282), and one-line *reasons* need the same scrutiny as the rule ("must fail only when the service is failing" can be read as licensing a degraded report from a merely *busy* service, which is the inversion the rule exists to prevent).
