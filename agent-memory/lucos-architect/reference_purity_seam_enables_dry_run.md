---
name: purity-seam-enables-dry-run
description: Dry-run/testability is a consequence of a purity seam (pure compute returning a value, caller chooses effects) — not of a --dry-run flag threaded through effectful code
metadata:
  type: reference
---

**A dry-run mode is a *consumer choice*, not a feature.** Code gets a cheap, safe dry-run exactly when it's split so that a pure function computes a result and the *caller* decides what effects to apply to it. Code that fuses compute-and-effect into one procedural function can only get a dry-run by threading a boolean through the effectful path — which is fragile, and unsafe by default.

**The lucos_repos case (2026-07-14, #469) is the clean A/B:**
- `conventions` = pure checkers behind `Check(ctx) Result`. The caller files issues *or* serialises to JSON. So `audit --dry-run` (ADR-0003) came essentially for free.
- `c4.go`'s `generateAndCommitC4()` fuses four responsibilities — gather inputs / build model / **file audit issues** / commit artifacts. No seam. Result: no dry-run mode, untestable wiring, and a false-positive shipped (#467).

**Why the seam beats the flag — the safety argument, which is the persuasive one:** with a seam, read-only is *structurally* guaranteed — the pure function cannot file an issue because it has no client and no token. With a flag, read-only depends on every future contributor remembering to check it. Concretely in #469: the obvious "just call `generateAndCommitC4()` from the dry-run path" would have filed **real** issues from PR branches, because `NewAuditSweeper` unconditionally sets a live `issueClientFactory` and the dry-run CI job holds the estate App token. The effectful call sat *before* the credential nil-check that would otherwise have stopped it — so the only existing protection was incidental, not designed.

**How to apply:**
- Reviewing any "add a dry-run / test mode / preview" request: the deliverable is the seam, not the flag. Locate where compute ends and effect begins; if there's no boundary, that's the actual ticket. Estimate accordingly — it's a refactor, not a feature.
- Reviewing a design that will need verification later: insist the compute stage return a value rather than perform writes. Retro-fitting the seam costs far more than designing it in.
- **Argue for the seam in the ADR, not just the PR.** A seam with no documented rationale gets silently re-fused by the next person adding a probe or a write. The durable risk is erosion, not the initial code.
- Pure-compute stages also unlock testing at the right altitude — see [[feedback_parse_reference_data_never_handbuild]] (§test fixtures): function-level tests can't catch input-*selection* bugs; a pure `build(inputs) → model` can, because the test supplies the inputs the production caller would have constructed.

Related: [[feedback_reused_mechanism_inherits_safeguards]] (the review lens that surfaces these gaps).
