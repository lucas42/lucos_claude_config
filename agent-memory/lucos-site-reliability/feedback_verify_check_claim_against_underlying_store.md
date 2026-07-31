---
name: feedback-verify-check-claim-against-underlying-store
description: A monitoring check's debug string is a claim, not evidence — verify it against the underlying data store before building any narrative on it, especially before a 2nd/3rd/4th occurrence hardens into a "pattern"
metadata:
  type: feedback
---

**Before treating a monitoring check's `debug` string as fact — and absolutely before letting repeat occurrences harden into a "recurring pattern" — verify the claim against the underlying data store the check is supposed to be measuring.**

**Why:** 2026-07-31, `lucos_locations` `location-freshness`. Across five ops runs (07-15, 07-19, 07-23, 07-27, 07-31) I read `"Last recorded location data is 108023 seconds old"` and concluded, every time, "genuine client-side gap, phone stopped publishing, server exonerated". I wrote it up five times, escalated a "worsening trend" (31h → 18h → 1min → 32h → 49h) to team-lead, and lucas42 asked for a ticket on the phone. One query of the recorder's `.rec` store destroyed the whole thing in about a minute: **2 of the 3 alerts were false positives** (true ages 47 minutes and 3h29m against a reported 30h), and during the "49-hour gap" the recorder received 18 fixes live. There was no worsening trend and no client-side failure — just one ordinary 32h stationary spell and a check that pins its value and then tracks wall-clock.

I never checked because the check *was the thing I had just helped specify* (#91), and each new occurrence made the story feel more established rather than less. Repetition felt like corroboration. It was five repetitions of one unverified reading.

**How to apply:**

- **Ask what the check reads, then read it yourself.** `location-freshness` read the recorder's `last` *cache* via `/api/0/last`; the truth lived in the `.rec` *store*. Different code path — and that gap is precisely where the bug was. Any check that queries an API for a derived number has an underlying store you can query independently.
- **Get the timestamp semantics right, or you'll fabricate a second wrong story.** I nearly concluded "backlog flushed on reconnect" because the `.rec` leading column is the *fix* time (`tst`). The recorder's own receive time is `created_at` / `isorcv`. A check measuring a *device's* clock cannot tell you about *your* ingestion health.
- **Strongest trigger: an alert whose reported value keeps climbing while the thing it measures is demonstrably moving.** That is a pinned/stuck value, not a real outage. Read the *recovery* event's `debug` too — the alert-time value is tautologically ~threshold and tells you nothing; the last-failing-poll value is what exposes stuckness.
- **A finding that exonerates our own infrastructure deserves *more* scrutiny, not less.** "It's the client / it's upstream / it's outside our control boundary" is the conclusion that ends investigation, so it's the one most likely to be wrong and least likely to be caught. I reached for it five times without once testing it.
- **When you correct a narrative you authored, say so explicitly in the artifact** — I put a "Correction to prior reports" section in lucos_locations#105 naming the five reports that were wrong, because those reports outlive the conversation and someone will read them.

Related: [[feedback_verify_root_cause_by_reproduction]], [[feedback_correlation_is_not_confirmed]], [[pattern_locations_silent_data_gap]], [[feedback_treat_empty_tool_output_as_unknown]].
