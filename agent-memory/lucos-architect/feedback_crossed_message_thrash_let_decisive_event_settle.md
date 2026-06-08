---
name: crossed-message-thrash-let-decisive-event-settle
description: In a crossed-message coordination loop over an equivalent/reversible choice, stop chasing reversals; verify live state, hold the reversible action, let the decisive irreversible event settle it
metadata:
  type: feedback
---

When coordinating a low-stakes, **reversible** choice (e.g. which of two equivalent GitHub issues is "the tracker") and messages with the coordinator are crossing — each of you acting on the other's stale state — STOP chasing each reversal. Every unilateral action you take crosses with their next in-flight message and compounds the inconsistency.

**Why:** 2026-06-08, the ADR-0012 AAAA-glue tracker flip-flopped lucos_dns#107 ↔ lucos#227 three times. team-lead and I kept acting on each other's stale messages: I closed #227 + pointed ADR→#107 (their msg A); they reopened #107 not knowing; I reopened #227 + pointed ADR→#227 + flipped the PR ready (their msg B); they then asked to point at #107 again (msg C, already stale). Each "fix" crossed with the next message. The choice was purely cosmetic — both issues track the identical work — so the coordination cost of the flips dwarfed any value of "the right one."

**How to apply:**
1. **Re-verify live state before every action** (issue open/closed + labels, PR draft/merged, what the doc actually references). Never act on the state *implied* by a teammate's message — in a fast loop it is already stale by the time you read it.
2. **Hold the reversible / contested action** (e.g. closing one of two trackers). Instead surface the precise current state plus a single binary with a recommendation, and act exactly once on the answer.
3. **Let the decisive, irreversible event settle it.** Here the PR auto-merging (ADR landing on `main` referencing #227) made #227 the natural answer; I stopped and pointed everyone at that fact rather than opening a fresh PR to re-flip `main`. The thing that can't be cheaply undone wins — converge onto it.
4. **Name equivalent choices early and converge.** If two options are functionally identical, say so and pick the zero-churn one; don't optimise a cosmetic decision through multiple round-trips.

Related: [[feedback_verify_past_tense_work_claims]], [[feedback_refetch_state_before_writing_final_artifact]].
