---
name: reused-mechanism-inherits-safeguards
description: When a new subsystem reuses an existing output/side-effect mechanism, check it also inherits that mechanism's pre-merge safeguards — blast radius is inherited by default, guard rails are not
metadata:
  type: feedback
---

When a design says "this maps directly onto the existing X machinery" / "the same engine that does A can do B", **ask separately whether it also inherits X's safeguards.** Reusing a mechanism inherits its *blast radius* automatically; it does **not** inherit the guards built around that mechanism, because those usually live in a different layer (a CI gate, a review step, a rate cap) that was scoped to the original caller and never re-scoped.

**Why:** lucos_repos#469 (2026-07-14). ADR-0003 (2026-03-19) built a CI dry-run gate whose *stated* purpose was to stop a logic bug mass-filing false-positive audit issues (after ~26- and ~54-issue incidents). ADR-0006 (2026-06-14) added a C4 divergence pipeline that deliberately routed its findings through the *same* ADR-0004 issue-filing engine — inheriting the estate-wide issue-filing blast radius — but nothing extended ADR-0003's gate to cover it. Nobody decided to exclude it; the gate simply predated the pipeline by three months, and ADR-0003's "What this does NOT solve" section couldn't list a thing that didn't exist. The gap then produced precisely the failure ADR-0003 existed to prevent (a false-positive finding filed against a repo, reaching production unseen). **The scope of a safeguard is set by what existed when it was written; the scope of a mechanism grows with every new caller.** That divergence is silent and widens over time.

**How to apply:** Two triggers.

1. *Reviewing a design that reuses an existing mechanism* — for each safeguard on the original mechanism, ask "does the new caller sit behind this too?" If the safeguard is a CI gate or review step, check what it actually invokes (the gate calls `conventions.All()`, not the new path). Say so in the review; it's a cheap finding with a real incident behind it.
2. *Reading an ADR's exclusions* — "What this does NOT solve" enumerates what was known at authoring time. Absence from that list is **not** a decision to include; for anything postdating the ADR it means nothing at all. Check the dates before treating a scope boundary as deliberate. Framing it as "the gate's scope is narrower than its own justification" is more accurate, and more persuasive, than "the gate has a bug".

Related: [[feedback_check_originating_decision_before_forking]] (read the originating decision, don't infer intent), [[feedback_defense_in_depth_reverts_to_baseline]] (a failed extra layer leaves the baseline, not a hole), [[feedback_check_adr_before_advising]] (check the ADR before advising). The enabling fix is usually a **purity seam**, not a flag — see [[reference_purity_seam_enables_dry_run]].
