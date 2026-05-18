---
name: feedback-silent-fallbacks-are-a-security-risk
description: When evaluating a "remove the silent fallback" proposal vs "keep the fallback for defence-in-depth", weigh the visible-failure-vs-defence-in-depth trade and remember that silent fallbacks can themselves be a security risk (data-poisoning attacks slip past undetected)
metadata:
  type: feedback
---

Silent fallbacks aren't only an operational risk — they're a security risk too. If a fallback path silently substitutes "wrong but plausible" data when the primary lookup fails, an attacker who can poison an upstream source can persist bad data indefinitely, because no alarm ever fires. The strict-mode equivalent (e.g. lucas_arachne#371 removing the triplestore fallback) makes the failure mode loud and within-hours-visible — far easier to detect and respond to than "the data has been subtly wrong for three weeks and we never noticed."

**Why:** lucos-security raised this framing on 2026-05-18 in response to my incident report on the `owl:AsymmetricProperty` outage. My report had framed the trade-off as "durably-visible failure vs. defence-in-depth," picking visible failure. Security's flip: visible failure *is* better defence-in-depth from a data-integrity angle, because silent-fallback failure modes are friendly to data-poisoning attacks.

**How to apply:**
- When reviewing or proposing a "remove the silent fallback" change (the inverse of "add defence-in-depth"), state both perspectives explicitly: operational (visible vs. hidden failure) AND security (data-integrity exposure of silent paths). Don't default to the operational framing alone.
- When consulted on an incident where the loud-failure mode was the proximate cause, resist the reflex to recommend "add a fallback for defence-in-depth" — first check whether the previous quiet-fallback mode was actually safer or just nicer-looking.
- Related observation from the same incident: rdflib's non-deterministic iteration was what made the bug *reproducible* enough to be noticed at all. If iteration order had always picked the safe rdf:type first, the bug could have flapped intermittently for ages. Chaotic ordering is occasionally a feature, not a bug — worth remembering when proposing "make this deterministic" changes to upstream behaviour.
