---
name: Pressure-test decision thresholds before agreeing to a measurement window
description: When setting a "ship X then decide Y by measurement" rule, check that the threshold is reachable given the data mix — single-metric thresholds can have structural ceilings that make them unreachable
type: feedback
---

When you set a quantitative rule like "if skip rate ≥ 90% then close as not-needed", check the threshold's **reachability** against the actual data mix, not against the optimistic estimate in the originating ADR.

**Why:** On lucos_arachne #392 (ADR-0002 Option 2 checkpoint, 2026-05-06), I set a "skip rate ≥ 90% → close as not-needed" rule on 2026-04-20. The ADR's "plausibly >90%" estimate assumed live sources change infrequently. They change every cycle. With 3 live sources × 12 cached ontologies + 1 other (16 total), the structural ceiling for skip rate is 87.5% (only 1 of 3 live sources unchanged) — 90% requires 2 of 3 live sources unchanged on the same cycle, which the source mix makes unlikely. The threshold was unreachable in practice. The bloat metric saved the decision (18× growth in 3 days made the call obvious anyway), but the conflict between signals delayed the decision and forced an extra triage round.

**How to apply:** For any "ship X, measure Y, decide by threshold T" rule:
1. **Two metrics, not one.** Pair a "primary outcome" metric (the thing you actually care about) with a "is the mechanism working at all?" metric (corroboration). Don't let the mechanism metric override the outcome metric.
2. **Pressure-test the threshold's reachability.** What's the structural ceiling given the data mix? If the ceiling is below the threshold, the threshold is unreachable and the rule is broken before measurement starts.
3. **Use existing data to sanity-check the estimate.** ADR-0002's "plausibly >90%" could have been checked against ingestor logs before being baked into a decision rule. I didn't ask; the SRE noticed in production.
4. **Compressing observation windows is fine; sloppy thresholds inside the compressed window are not.** Speeding up the schedule is good. Skipping the calibration check is not.

This applies whenever an ADR commits to "ship A, then decide whether B is still needed by measurement." The decision rule is part of the ADR's contract — it deserves the same rigour as the design itself.
