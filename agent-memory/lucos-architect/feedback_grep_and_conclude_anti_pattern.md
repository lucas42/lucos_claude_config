---
name: feedback-grep-and-conclude-anti-pattern
description: Absence claims ("X doesn't consume Y", "X has no other home") are load-bearing and need real evidence — a zero-hit grep is weak, and a partial read of the files you happened to open is none at all. Verify the entry point / grep the whole repo before asserting a negative in design advice.
metadata:
  type: feedback
---

# Don't conclude absence without searching for it

**Rule:** Any claim that something *doesn't* exist or *isn't* used is load-bearing evidence, and needs to be earned. Two distinct failure modes:

1. **Greped and got zero → weak evidence.** Consumer wiring often dispatches on patterns/suffixes rather than literal names, so a zero-hit grep proves little. Read the actual entry point (webhook handler, message-queue subscriber, route table).
2. **Never greped at all → no evidence.** Concluding "nothing else handles this" from the three files you opened for some other purpose. This one is more dangerous because it doesn't *feel* like a search failure — it feels like knowledge.

Both matter most when the negative is what **justifies adding complexity** ("this has no other home, so build it here"). See persona Self-Verification #5.

**Why:** Consumers frequently dispatch by pattern rather than by literal name:
- Webhook handlers may match on event-name SUFFIX (`*.endswith("Updated")`) rather than on a hardcoded event-type list.
- Route handlers may extract a `type` field from the payload and dispatch dynamically.
- Generic adapters may consume "anything with shape X" without naming the events explicitly.

A grep for the emitter-side string ("loganne", "updateLoganne", an event name) will find emitters but miss consumers that receive events via a generic webhook endpoint. The mismatch is silent — the grep returns 0, you conclude "no consumer", and the design advice that follows is wrong.

**How to apply:** Before stating "X doesn't consume Y" in a design summary:
1. Identify X's actual entry point (server.py, routes file, lambda handler, etc.) — usually the file with the HTTP handler / message-queue worker / cron entry.
2. Read it. Look for dispatch logic — switch statements, suffix-matches, dynamic routing.
3. Then state your conclusion.

**Incident:** 2026-05-17, mid-conversation with lucas42 about Loganne event vocabulary across the cross-system Person design. I greped `lucos_arachne/*.py` for `loganne|Loganne|updateLoganne`, found only emitter sites in `compact.py` and `ingest.py`, and concluded confidently that "arachne does not consume any Loganne event. It's purely pull-based via scheduled re-fetch." This was wrong — `ingestor/server.py` is a webhook handler that dispatches by event-name suffix (Created/Added/Updated/Deleted/Merged), so arachne consumes ~18 event types from contacts + eolas + media. lucas42 caught it with "arachne consumes 12 different loganne event types".

The wrong conclusion led to a downstream cascade of bad advice — multiple recommendations had to be revised:
- The `personMerged` event would have been silently dropped by arachne's suffix-match.
- The "Layer 2 staleness is hours/days" framing in arachne#539 was wrong (it's seconds).
- The "out of scope: event-driven re-ingest" paragraph I'd authored on arachne#539 was wrong-premised.

Trigger: any time I write "system X is pull-based" or "system X doesn't consume events" in a design summary based on a single grep, **stop and verify by reading the entry point**.

**Sibling incident (2026-07-03, lucos_notes#445 re-login regression):** same failure class, different shape — inferring a *runtime cause* from a *static code gap* without the runtime signal. I found notes + seinn both lack the JWKS last-known-good wrapper (real code gap) and concluded that gap was *driving* the frequent re-logins — and worse, wrote "confirmed against seinn" when seinn was actually the disconfirming control. SRE's router log settled it: **0 `/auth/remint` from notes vs 160 from seinn** — the real cause was notes' service-worker render path emitting `aithne-origin=""` (keepalive never fires → plain 15-min token expiry); the JWKS gap had 0 runtime occurrences. Two compounding lessons: (1) a code gap is a *latent* risk, not evidence it's the *active* cause — get the runtime signal (a counter, a log, a probe) before naming it the driver; (2) **when a comparison/control case shares the same code property, its divergent *behaviour* is the disconfirming test** — seinn sharing the gap but staying logged in should have killed the hypothesis immediately. Before writing "confirmed against X", check that X actually behaves as the hypothesis predicts, not just that it shares the code path. (Governing rule: persona self-verification #10 — verify the consumer/runtime, not just the capability.)

**Sibling incident (2026-07-13→14, lucos_photos#471 — failure mode 2, the never-greped kind):** designing a face-grouping flag, I justified a dedicated `person_flag` table with a `reason_code` Enum partly on the grounds that the "wrong profile picture" reason *"is not a face-regrouping correction and has no other home."* It had a home. `Person.profile_auto_generated` already exists and `generate_profile_picture` (`shared/lucos_photos_common/jobs.py:798`) already skips regeneration when it's `False` — a tested branch. I'd traced `models.py`/`people.py`/`faces.py` (the files relevant to *faces*) and never followed the column into the worker. One `git grep profile_auto_generated` would have found it in seconds — and would also have shown that no endpoint writes the column at all, making the branch unreachable (raised as lucos_photos#473).

Two compounding lessons:

- **Scope the search to the *concept*, not to the files you're already in.** I was reviewing a face-grouping change, so I read the face-grouping files. "Does anything handle profile pictures?" is a different question and needed its own search. The trap is that the partial read felt sufficient *because it was thorough within its own frame*.
- **A justification that contradicts your own analysis elsewhere is the tell.** In the same comment I argued flag history was the ML training signal (to justify the table) and, two paragraphs later, that the ML signal was the confirmed-`Face` corpus and *not* the flag. Both can't be true. Nobody caught it for a day; lucos-ux eventually did, from the other end (lucas42 offered to drop the reason on cost grounds). **Re-read your own document for internal contradiction before posting** — self-verification #6/#3 pointed at yourself. Once both errors were caught the entire table + enum collapsed to one nullable column (`Person.flagged_at`), mirroring the existing `is_background` precedent I should have reached for first.

Trigger: writing "has no other home", "there's no existing pattern for this", "nothing already does X" — **especially when it's the reason you're adding a table, column, endpoint, or service.** Grep first.

Cross-ref: [[reference_arachne_webhook_consumer]] (the specific arachne details); [[feedback_apply_frame_review_to_own_reasoning]] (the self-directed-scrutiny sibling).
