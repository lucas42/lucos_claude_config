---
name: feedback-verify-check-claim-against-underlying-store
description: Verifiability, both directions — a check's debug string is a claim not evidence (verify against the underlying store); scrutinise hardest what you agree with; read the artefact not its description; and write in the falsifiable form so others can catch you
metadata:
  type: feedback
---

## ⚠️ Verify SELF-INCRIMINATING claims too — confession is not evidence

The claims least likely to be checked are the ones that make the speaker look bad, because nobody argues against being told they erred. A teammate's account of **their own mistake** is still an unverified claim.

**2026-08-06:** team-lead told me their wrong retraction had "put a false fact into `lucos-system-administrator`'s persistent memory". I accepted it and repeated it back in a written ledger. It was false — the sysadmin had gone from their own caveat straight to their own GraphQL verification, skipping the bad interim read entirely. Falsified in seconds:

```bash
git log --oneline -S "did join the rollup" -- agent-memory/lucos-system-administrator/   # -> 0 commits
```

Nobody had checked, precisely because the claim was against its own author's interest — and the "harm" was asserted about a *third party* who was never asked.

**How to apply:** apply the same verification bar to admissions as to boasts. Especially when someone reports collateral damage to a third party's state (their memory, their file, their branch), check the third party's actual state before repeating it. And when *you* are the one confessing, hedge the blast radius: "I may have propagated this to X" — not "I corrupted X's memory" — unless you have read X's memory.

**Before treating a monitoring check's `debug` string as fact — and absolutely before letting repeat occurrences harden into a "recurring pattern" — verify the claim against the underlying data store the check is supposed to be measuring.**

**Why:** 2026-07-31, `lucos_locations` `location-freshness`. Across five ops runs (07-15, 07-19, 07-23, 07-27, 07-31) I read `"Last recorded location data is 108023 seconds old"` and concluded, every time, "genuine client-side gap, phone stopped publishing, server exonerated". I wrote it up five times, escalated a "worsening trend" (31h → 18h → 1min → 32h → 49h) to team-lead, and lucas42 asked for a ticket on the phone. One query of the recorder's `.rec` store destroyed the whole thing in about a minute: **2 of the 3 alerts were false positives** (true ages 47 minutes and 3h29m against a reported 30h), and during the "49-hour gap" the recorder received 18 fixes live. There was no worsening trend and no client-side failure — just one ordinary 32h stationary spell and a check that pins its value and then tracks wall-clock.

I never checked because the check *was the thing I had just helped specify* (#91), and each new occurrence made the story feel more established rather than less. Repetition felt like corroboration. It was five repetitions of one unverified reading.

**How to apply:**

- **Ask what the check reads, then read it yourself.** `location-freshness` read the recorder's `last` *cache* via `/api/0/last`; the truth lived in the `.rec` *store*. Different code path — and that gap is precisely where the bug was. Any check that queries an API for a derived number has an underlying store you can query independently.
- **Get the timestamp semantics right, or you'll fabricate a second wrong story.** I nearly concluded "backlog flushed on reconnect" because the `.rec` leading column is the *fix* time (`tst`). The recorder's own receive time is `created_at` / `isorcv`. A check measuring a *device's* clock cannot tell you about *your* ingestion health.
- **Strongest trigger: an alert whose reported value keeps climbing while the thing it measures is demonstrably moving.** That is a pinned/stuck value, not a real outage. Read the *recovery* event's `debug` too — the alert-time value is tautologically ~threshold and tells you nothing; the last-failing-poll value is what exposes stuckness.
- **A finding that exonerates our own infrastructure deserves *more* scrutiny, not less.** "It's the client / it's upstream / it's outside our control boundary" is the conclusion that ends investigation, so it's the one most likely to be wrong and least likely to be caught. I reached for it five times without once testing it.
- **Scrutinise hardest what you already agree with — agreement is the condition under which nobody checks.** Adversarial claims get checked automatically; a teammate confirming your own analysis does not, because there's no friction to prompt it. Named by lucos-architect 2026-07-31 after we'd spent an afternoon reaching the same conclusions: *"that's the right instinct even between the two of us — arguably especially, since we've been agreeing all afternoon and that's exactly the condition under which nobody checks."* Concretely that afternoon: I verified two of their load-bearing facts (zero open Dependabot PRs org-wide; Dependabot's verbatim close-reply) precisely because I agreed with the conclusion they supported. Both held — but the check cost one command and the alternative was a decision to lucas42 resting on an unverified premise we'd each assumed the other had tested.
- **Read the artefact, never its description.** The generalisation of the whole 2026-07-31 mbstring incident: every substantive correction that day came from opening the thing rather than trusting its name — `_info.php`'s actual includes rather than "the health endpoint", the container healthcheck's actual `test` line rather than "the stack-boot job", Dependabot's actual reply rather than "closing the PR". A guard, check, or ticket named for doing X is not evidence that it does X. See [[pattern_info_endpoint_boundary]] for the `/_info` smoke-test trap this produced.
- **When you correct a narrative you authored, say so explicitly in the artifact** — I put a "Correction to prior reports" section in lucos_locations#105 naming the five reports that were wrong, because those reports outlive the conversation and someone will read them.

**The other direction — write so you can be caught. Prefer the falsifiable form, and treat being corrected as its price rather than evidence against it.** lucos-architect's corollary, 2026-07-31: their decision table was corrected partly *because* it was specific enough to contain a checkable wrong cell — a vaguer recommendation would have carried the same error with nothing to catch it on. The failure mode to avoid isn't being wrong in public; it's **retreating into hedged generality to keep the error count down, which hides errors instead of removing them.** The temptation is strongest right after a day of corrections, which is exactly when precision is most valuable.

This does NOT conflict with CLAUDE.md's "hedge unverified claims". Hedging is for claims that run past your evidence — say "I haven't verified, but". It is not licence to blur a claim you *do* have evidence for into something unfalsifiable. Concretely: a report saying "monitoring has gaps" cannot be wrong and teaches nothing; "`_info.php` requires `api.php` only and never includes `views/field.php`, so a CI job curling `/_info` would have gone green" can be checked in one command — and if it's wrong, someone will say so, which is the point. **Specific-and-checkable, or hedged-and-labelled — never vague-and-confident.**

Severity note (mine, same thread): distinguish a wrong *argument* from a wrong *recommendation*. A bad cell in a comparison table misleads whoever reads that thread; a bad remedy in a merged incident report misleads every future reader of the durable artifact, including everyone who never sees the discussion. Weight review attention accordingly — scrutinise the advice hardest.

Related: [[feedback_verify_root_cause_by_reproduction]], [[feedback_correlation_is_not_confirmed]], [[pattern_locations_silent_data_gap]], [[feedback_treat_empty_tool_output_as_unknown]], [[pattern_info_endpoint_boundary]].
