---
name: vague-aesthetic-hedging
description: Don't reach for vague aesthetic words ("ugly", "clean", "elegant") as load-bearing arguments — name the actual concern or drop it
metadata:
  type: feedback
---

When defending an architectural recommendation under challenge, do not lean on vague aesthetic words — "ugly", "clean", "elegant", "feels not-quite-right" — as if they were substantive arguments. They are placeholders for concerns the speaker hasn't articulated. If pressed, either name the actual concern in concrete terms (latency, complexity, code reuse, failure mode) or admit the concern doesn't hold up.

**Why:** On lucas42/lucos_media_metadata_api#246 (2026-05-19, architect chat), I labelled "Artist lives in media_api with a member field pointing at eolas:Person URIs" as "ugly". lucas42 asked me to explain why. On close inspection, the label didn't hold:

- "Cross-system writes" — not actually a write concern; the cross-system part is the *read*, and media_api already has the reconcile pattern for that.
- "Eolas-shaped relations on a media entity" — media's tag predicates already point at eolas URIs (composer, producer, mentions); a members field on Artist is the same pattern applied at the entity layer.
- "Admin tooling" — real edge but smaller than I framed (eolas's Django admin only autocompletes eolas:Person URIs, not contacts:Person, so the advantage covers maybe half the cases).

The label was vague hedging that smuggled in unexamined preferences. When I unpacked it honestly, the recommendation actually changed.

**How to apply:** Before using "ugly" / "clean" / "feels right" in an architectural argument, ask: *what specific failure mode, cost, or constraint am I pointing at?* If you can name one, write that instead. If you can't, drop the claim. The word "ugly" in a recommendation is a tell that you haven't finished thinking. Related: [[apply_frame_review_to_own_reasoning]], [[check_value_when_fix_complexity_grows]].
