---
name: feedback-verify-premise-not-just-quotes
description: When a teammate hands me a structural domain claim ("X is impossible") OR an incident-causation claim ("the cause was X"), verify or explicitly attribute the premise before building inference — or restating it as fact — on top of it
metadata:
  type: feedback
---

When a teammate's framing rests on a structural domain claim ("structurally impossible to be real inbound", "X always routes via Y", "the harness can't do Z"), the cheap empirical check that would falsify the premise must be run before I build any chain of inference on top of it.

**Why:** During the 2026-05-14 team-lead phantom-message incident, `lucos-site-reliability` flagged a suspected phantom with the framing "Structurally impossible as a real inbound (SendMessage doesn't route to sender; task notifications come back as tool results, not as teammate-message blocks)." I took the premise as given and produced multiple rounds of analysis — stale-timestamp self-replay inference, in_progress correlation hypothesis, persona risk-surface ranking — all conditioned on the suspected-phantoms being assistant-generated. `lucos-security`'s targeted re-grep then resolved the messages as `role: user` real inbound task-system notifications. The whole inference tower had been built on an unchecked premise. One `grep 'role:' for the task_assignment payload shape` on the SRE's jsonl would have falsified the premise in seconds.

**How to apply:** Whenever a teammate's reasoning depends on a structural claim of the form "X is impossible / X always behaves like Y", before extrapolating, ask: "what's the one-line bash/grep command that would falsify this?"

- If the falsifying check is cheap (single grep, single file read, single API call), run it.
- If the check is not cheap or not possible, flag the premise explicitly as a load-bearing assumption that all subsequent analysis is conditional on. Don't bury it as a footnote.
- This is the same provenance-verification discipline as the recipient-side rule for accusations ("verify the quote against primary source") — extended one layer up to the *premise* of someone else's reasoning, not just the quotes inside it.

**Incident-causation premises (2026-05-29, lucas42/lucos_media_metadata_api#278).** A second flavour: when asked to design a *durable fix for an incident*, the stated root cause may itself be an unverified inference. I was routed #278 to make the composer/producer save path resilient, framed as the cause of the track-22829 save-502. I designed it soundly — but in my design comment I wrote "this is the incident path for track 22829" as established fact. `lucos-site-reliability` then *reproduced* the real cause: an Album URI in the unscoped `about` field → 400 origin-rejection → unlogged → manager hardcoded 502. Composer/producer was never involved. The design still stood on its own merits (a sync eolas call on a write hot path is a real fragility), but the incident framing — and the urgency/priority that rode on it — was wrong.

The actionable difference from the structural-claim case: here the falsifying check was *not* cheap (it needed reproduction, which is the SRE's job, not mine). When the check isn't yours to run cheaply, the rule is **attribute and hedge, don't restate as fact**: write "the reported cause is X" / "per the incident analysis, X", never "X is the cause", in any artifact (GitHub comment, ADR, design doc) — and explicitly note the design's validity is independent of whether that causation holds, so a later correction doesn't invalidate the work, only its priority. An unhedged causation claim in a durable artifact becomes the permanent record's "fact" and propagates.

**Distinguishing this from related lessons:**

- [[feedback_apply_frame_review_to_own_reasoning]] is about *flipping a recommendation* based on a teammate's summary. The new lesson is about *building inference chains* on an unverified premise.
- [[feedback_check_working_counterexample_first]] is about doubting "X is universally broken" by finding a passing case. The new lesson is broader: doubt any structural domain claim where the falsifying check is cheap.

Source: `lucas42/lucos#151` incident report, Stage 5 / 5a (interpretation (c) resolution); my SendMessage thread with `lucos-site-reliability` 2026-05-14.
