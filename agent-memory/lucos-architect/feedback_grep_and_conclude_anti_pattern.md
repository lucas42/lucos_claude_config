---
name: feedback-grep-and-conclude-anti-pattern
description: A single grep for "X" finding zero hits is weak evidence that X doesn't happen — especially for consumer-side wiring, which often dispatches on patterns/suffixes rather than literal names. Always look at the entry point (route handler, webhook controller) directly before claiming a system doesn't consume something.
metadata:
  type: feedback
---

# Don't grep-and-conclude on consumer wiring

**Rule:** When asking "does system X consume Y?", a single grep that returns zero hits is weak evidence. Verify by reading the actual entry point (webhook handler, message-queue subscriber, route table) before stating a conclusion in design advice.

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

Cross-ref: [[reference_arachne_webhook_consumer]] (the specific arachne details).
