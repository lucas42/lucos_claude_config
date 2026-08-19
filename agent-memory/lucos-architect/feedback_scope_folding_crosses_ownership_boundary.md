---
name: scope-folding-crosses-ownership-boundary
description: Folding a dependency "into scope" can push the same gap up an ownership boundary; check who can land each half, and prefer an ordering that makes the split safe over coordination that manages it
metadata:
  type: feedback
---

When you fold a dependency into a ticket's scope to stop it becoming a lost follow-up, **check that the assigned owner can actually land every part of the acceptance criteria.** If one half belongs to a different owner, the gap you closed reappears one layer up: the ticket stalls at its final step, or closes green with the bar unmet.

**Why:** 2026-08-19, `lucos_claude_config#131`. I put a `~/.claude` ops-check reader change in scope so it couldn't be dropped as a follow-up — correct instinct. But `agents/sre-ops-checks.md` is the coordinator's file by ownership convention, so the implementer would have hit the boundary at the last step. Second instance that session of a fix reappearing a layer up.

**How to apply — prefer ordering over coordination.** Before proposing an atomic commit or a permission variance, check whether the two halves are *asymmetric*. They usually are, and then one order is safe and the other isn't:

- emitter before reader → events fire unread (the original failure mode, reintroduced)
- reader before emitter → the reader matches nothing yet; a harmless no-op

So sequence it rather than synchronise it. Bonus: the safe-first half can land at dispatch time, off the critical path. Write it into acceptance as an **ordering**, because "both must land" reads as requiring simultaneity.

**Ownership convention ≠ permission — verify which.** `commit-claude-main` resolves `--app` against `personas.json` and has **no path filtering and no per-persona allowlist**, so mechanically any persona can commit any `~/.claude` path. The restriction is the coordinator-owns-persona/skill/routine-files *convention*. Keep the convention, but never write "X cannot commit this" into a durable record — a wrong impossibility closes a door that is actually open, per [[feedback_absolute_then_hedge_detector]].

**Speculative non-goals: record, don't file.** Related call the same day (coordinator's, and better than my instinct): an explicit v1 non-goal with no observed instance gets recorded where the decision lives, not filed as a ticket that would age in the queue with no trigger. File when there's a case to attach. Do write the reasoning onto the ticket so it doesn't later read as an oversight.

Related: [[feedback_file_followups_during_design]], [[reference_inplace_write_vs_running_script]].
