---
name: feedback-avoid-coincidence-default
description: When two unusual things happen together, default to "one caused the other", not "coincidence"
metadata:
  type: feedback
---

When investigating an incident where two unusual things happened in the same window (e.g. "burst of N errors" + "M webhook failures"), my default framing should be "one caused the other"; treating them as coincident requires positive evidence, not just absence of evidence either way.

**Why:** On 2026-05-21 I described a 14-event errored-track burst and 7 simultaneous webhook ETIMEDOUTs as "two coincident things, possibly overlapping". lucas42 pushed back: a wave of 14 error events into loganne is rare enough to be the cause-not-coincidence default. He was right — access logs subsequently showed loganne's outbound stalled entirely for ~87 seconds during exactly that burst, then drained a backlog in 23 seconds. The events caused the failures via outbound saturation.

**How to apply:** Phrase initial hypotheses as "X caused Y" with the cause-and-effect chain spelled out; only retreat to "X and Y coincided" when concrete evidence rules out causation (e.g. timing inverts, different hosts, different timescales). "I can't prove causation from the data I have" is not the same as "they are coincident" — when something rare happens twice in the same minute, the prior is causation.

Related: [[feedback-correlation-is-not-confirmed]] — the inverse rule. Causation as default hypothesis is *for investigation*; "confirmed causation" still needs evidence that rules out other plausible mechanisms.
