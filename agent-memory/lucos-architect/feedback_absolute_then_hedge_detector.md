---
name: absolute-then-hedge-detector
description: If you write an absolute and immediately hedge it, the hedge is the true claim — delete the absolute; and never make a quantitative claim without instantiating a quantity
metadata:
  type: feedback
---

Two detectors, both cheap, both self-contained — no external check needed.

**1. Absolute-then-hedge.** If you assert something absolutely and your *very next sentence* states the condition under which it fails, the hedge is the true claim and the absolute is decoration. Delete the absolute and lead with the condition.

**2. A quantitative claim with no quantity in it is a guess wearing a proof's clothing.** If the claim is about *how much* something helps (makespan, blast radius, cost, coverage), instantiate at least one real number before publishing. Reasoning about a structure abstractly and never asking what its actual values are produces confident, evidenced-*looking*, wrong answers.

**Why:** 2026-08-19, ops-check workload consultation. I read `routine/SKILL.md`, correctly identified Phase 1 as a parallel barrier gating triage, and concluded "rebalancing across a parallel barrier is a no-op by construction — move 15 minutes from SRE to me and the barrier waits 15 minutes on me instead". False. makespan = max(legs), not sum, so rebalancing an *unequal* set strictly reduces it; the legs were 37m / 3m / 3m / 5m and the move takes makespan 37→~22. My sentence only parsed if SRE's *total* were 15 — I silently modelled a **total** transfer and generalised to **partial** rebalancing, a different operation with different arithmetic.

The coordinator's catch: my own next sentence said "the same problem the moment their leg exceeds the shortened SRE leg" — which is exactly the boundary condition that falsifies the absolute. I wrote the refutation myself, one line later, and didn't notice.

**Error direction is the tell.** The false impossibility closed off the one option lucas42 had actually asked about, and it favoured me twice: it made delete-and-automate the only surviving lever (my recommendation), and it excused me from receiving any work. Self-Verification #5 already says to weight verification hardest on claims that *close* an option and to test the impossibility that favours your own recommendation. It didn't fire because I never instantiated a number — the measurement was one question away and the coordinator asked it, not me.

**Second-order lesson:** once the numbers arrived they also broke my *recommendation ranking*, not just the argument. The checks I proposed deleting were the monthly ones, already usually skipped, therefore contributing ~0 to the measured 37 minutes. Getting the quantity late doesn't just weaken a claim — it can reveal the whole proposal was aimed at the wrong target.

**How to apply:** before publishing any claim that a lever "can't work", "is a no-op", or "makes no difference" — instantiate one number, and re-read the following sentence for a hedge that contradicts it. Applies hardest in consultations where the closed-off option is the one you were specifically asked about.

Related: [[reference_ops_checks_duplicate_machinery]], [[feedback_verify_premise_not_just_quotes]], [[feedback_apply_frame_review_to_own_reasoning]].
