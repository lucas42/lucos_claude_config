---
name: role-duration-precision
description: When citing a specific role's duration in prose, verify against cv-extended.md dates before stating; don't round up
metadata:
  type: feedback
---

When writing duration claims about a specific role in cover-letter / textarea / CV-Summary prose (e.g. "For two years I was architect on X"), verify the actual start-to-end dates from `cv-extended.md` before committing the number.  Don't round up.

**Why:** 2026-05-27, in a textarea answer for a risk-intelligence vendor Staff IC, I wrote "For two years I was architect on the FT's Universal Publishing Platform."  The Architect-Content role ran Oct 2016 - Feb 2018 = ~17 months ≈ 1.4 years, not 2.  Even small rounding-up in concrete role-duration claims overstates Luke's tenure, and `cv-extended.md` is the authoritative source one keystroke away.  This is a *different* failure mode from the overlap-years rule (which is about sum-across-domains within a document) — this is about individual-duration accuracy tied to a specific named role.

**How to apply:**

- Any sentence in CV Summary / cover letter / textarea / form answer that says "[N] years" or "[X] months" referring to a specific role: cross-check against the date range in `cv-extended.md` before committing the number.
- Acceptable rounding (no overclaim): 11 months → "almost a year"; 13 months → "just over a year"; 22 months → "nearly two years"; 25 months → "over two years"; 17 months → "over a year" or "around a year and a half".  Anything that meaningfully overstates actual tenure is not acceptable.
- The "decade-plus at the FT" / "the bulk of my career" / "throughout this four-year period" framings don't need precise dates because they're broad anchors backed by visible CV dates.  The risk is when a SPECIFIC role gets a SPECIFIC number attached in prose, and the prose duration drifts from the actual role span.
- Self-check step in `/tailor` Step 11 letter-shaped artefact checks (added 2026-05-27 alongside this memory): scan drafted prose for any "[N] years" / "[X] months" claims tied to a named role; verify each against `cv-extended.md`.

**Triggered by**: a slip in 2026-05-27 worked tailoring (Architect-Content described as "for two years" in submitted textarea content when actual span was 17 months).  The post-submission memory sweep caught it; should have been caught in pre-submission self-checks.  Skill updated to add the explicit check.

Related: [[overlap-years-claim]], [[luke-voice]].
