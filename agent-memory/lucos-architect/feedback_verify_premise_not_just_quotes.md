---
name: feedback-verify-premise-not-just-quotes
description: When a teammate hands me a structural domain claim ("X is impossible") OR an incident-causation claim ("the cause was X"), verify or explicitly attribute the premise before building inference — or restating it as fact — on top of it
metadata:
  type: feedback
---

When a teammate's framing rests on a structural domain claim ("structurally impossible to be real inbound", "X always routes via Y", "the harness can't do Z"), the cheap empirical check that would falsify the premise must be run before I build any chain of inference on top of it.

**Why:** During the 2026-05-14 team-lead phantom-message incident, `lucos-site-reliability` flagged a suspected phantom with the framing "Structurally impossible as a real inbound (SendMessage doesn't route to sender; task notifications come back as tool results, not as teammate-message blocks)." I took the premise as given and produced multiple rounds of analysis — stale-timestamp self-replay inference, in_progress correlation hypothesis, persona risk-surface ranking — all conditioned on the suspected-phantoms being assistant-generated. `lucos-security`'s targeted re-grep then resolved the messages as `role: user` real inbound task-system notifications. The whole inference tower had been built on an unchecked premise. One `grep 'role:' for the task_assignment payload shape` on the SRE's jsonl would have falsified the premise in seconds.

**How to apply:** Whenever a teammate's reasoning depends on a structural claim of the form "X is impossible / X always behaves like Y", before extrapolating, ask: "what's the one-line bash/grep command that would falsify this?"

## The trigger this rule was missing: agreement

The rule above says *what* to do; it never said *when* it's most likely to go unapplied. It's **agreement**.

> **Agreement is the condition under which nobody checks.**

A teammate who *contradicts* me gets verified automatically — the friction prompts it. A teammate who *confirms* my analysis gets waved through, and if we each assume the other tested the shared premise, a decision reaches lucas42 resting on nothing. Adversarial claims are self-policing; concordant ones are not.

**How to apply:** when a teammate's message makes you think "good, that matches what I found" — that is the cue to run the check, not to skip it. Especially after a long stretch of agreeing with the same person on the same thread.

**Why:** 2026-07-31, lucas42/lucos#273 with `lucos-site-reliability`. We agreed all afternoon. Two shared premises (Dependabot supersession behaviour, the zero-open-PR baseline) were each nearly taken on trust because the other person had said them approvingly. Both got independently re-verified only because we each deliberately chose to; one — supersession-while-red — turned out to be *unverifiable*, and would have silently propped up a recommendation.

## Corollary: publish artifacts precise enough to be checkable

Related lesson from the same day. My decision table on #273 had a wrong cell, which SRE found. The reason it was findable is that the table was specific — a ✓/✗ per defence per incident. A vaguer recommendation ("boot-and-probe is the more robust approach") would have contained the *same* error with nothing to catch it on.

**So: prefer the falsifiable form.** A recommendation precise enough to be wrong is more valuable than one too vague to check, and being corrected on a specific claim is the cost of that value, not evidence against it. Don't retreat to hedged generality to reduce the error count — that hides errors, it doesn't remove them.

**This does NOT conflict with the standing "hedge unverified claims" rule** — they can read as opposed, so pin the distinction (SRE's phrasing, 2026-07-31):

> **Specific-and-checkable, or hedged-and-labelled — never vague-and-confident.**

Hedging is for claims that run *past* your evidence: say "I haven't verified, but". It is **not** licence to blur a claim you *do* have evidence for into something unfalsifiable. "Monitoring has gaps" cannot be wrong, teaches nothing, and survives every review untouched. "`_info.php` requires `api.php` only and never includes `views/field.php`, so a CI job curling `/_info` would have gone green" is checkable in one command — which is why it got challenged and why it's worth reading. Vagueness dressed as caution is the failure mode; the pull toward it is strongest right after being corrected.

Related: [[feedback_apply_frame_review_to_own_reasoning]], [[base-image-bump-incident-class]].

- If the falsifying check is cheap (single grep, single file read, single API call), run it.
- If the check is not cheap or not possible, flag the premise explicitly as a load-bearing assumption that all subsequent analysis is conditional on. Don't bury it as a footnote.
- This is the same provenance-verification discipline as the recipient-side rule for accusations ("verify the quote against primary source") — extended one layer up to the *premise* of someone else's reasoning, not just the quotes inside it.

**Incident-causation premises (2026-05-29, lucas42/lucos_media_metadata_api#278).** A second flavour: when asked to design a *durable fix for an incident*, the stated root cause may itself be an unverified inference. I was routed #278 to make the composer/producer save path resilient, framed as the cause of the track-22829 save-502. I designed it soundly — but in my design comment I wrote "this is the incident path for track 22829" as established fact. `lucos-site-reliability` then *reproduced* the real cause: an Album URI in the unscoped `about` field → 400 origin-rejection → unlogged → manager hardcoded 502. Composer/producer was never involved. The design still stood on its own merits (a sync eolas call on a write hot path is a real fragility), but the incident framing — and the urgency/priority that rode on it — was wrong.

The actionable difference from the structural-claim case: here the falsifying check was *not* cheap (it needed reproduction, which is the SRE's job, not mine). When the check isn't yours to run cheaply, the rule is **attribute and hedge, don't restate as fact**: write "the reported cause is X" / "per the incident analysis, X", never "X is the cause", in any artifact (GitHub comment, ADR, design doc) — and explicitly note the design's validity is independent of whether that causation holds, so a later correction doesn't invalidate the work, only its priority. An unhedged causation claim in a durable artifact becomes the permanent record's "fact" and propagates.

**Distinguishing this from related lessons:**

- [[feedback_apply_frame_review_to_own_reasoning]] is about *flipping a recommendation* based on a teammate's summary. The new lesson is about *building inference chains* on an unverified premise.
- [[feedback_check_working_counterexample_first]] is about doubting "X is universally broken" by finding a passing case. The new lesson is broader: doubt any structural domain claim where the falsifying check is cheap.

Source: `lucas42/lucos#151` incident report, Stage 5 / 5a (interpretation (c) resolution); my SendMessage thread with `lucos-site-reliability` 2026-05-14.
