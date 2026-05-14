---
name: feedback-verify-premise-not-just-quotes
description: When a teammate hands me a structural domain claim ("X is impossible", "X always works like Y"), verify the premise with a cheap empirical check before building inference on top of it
metadata:
  type: feedback
---

When a teammate's framing rests on a structural domain claim ("structurally impossible to be real inbound", "X always routes via Y", "the harness can't do Z"), the cheap empirical check that would falsify the premise must be run before I build any chain of inference on top of it.

**Why:** During the 2026-05-14 team-lead phantom-message incident, `lucos-site-reliability` flagged a suspected phantom with the framing "Structurally impossible as a real inbound (SendMessage doesn't route to sender; task notifications come back as tool results, not as teammate-message blocks)." I took the premise as given and produced multiple rounds of analysis — stale-timestamp self-replay inference, in_progress correlation hypothesis, persona risk-surface ranking — all conditioned on the suspected-phantoms being assistant-generated. `lucos-security`'s targeted re-grep then resolved the messages as `role: user` real inbound task-system notifications. The whole inference tower had been built on an unchecked premise. One `grep 'role:' for the task_assignment payload shape` on the SRE's jsonl would have falsified the premise in seconds.

**How to apply:** Whenever a teammate's reasoning depends on a structural claim of the form "X is impossible / X always behaves like Y", before extrapolating, ask: "what's the one-line bash/grep command that would falsify this?"

- If the falsifying check is cheap (single grep, single file read, single API call), run it.
- If the check is not cheap or not possible, flag the premise explicitly as a load-bearing assumption that all subsequent analysis is conditional on. Don't bury it as a footnote.
- This is the same provenance-verification discipline as the recipient-side rule for accusations ("verify the quote against primary source") — extended one layer up to the *premise* of someone else's reasoning, not just the quotes inside it.

**Distinguishing this from related lessons:**

- [[feedback_apply_frame_review_to_own_reasoning]] is about *flipping a recommendation* based on a teammate's summary. The new lesson is about *building inference chains* on an unverified premise.
- [[feedback_check_working_counterexample_first]] is about doubting "X is universally broken" by finding a passing case. The new lesson is broader: doubt any structural domain claim where the falsifying check is cheap.

Source: `lucas42/lucos#151` incident report, Stage 5 / 5a (interpretation (c) resolution); my SendMessage thread with `lucos-site-reliability` 2026-05-14.
