---
name: adr-standard
description: "lucos ADR-0014 — merged means decided, no Status field, and the first written ADR format standard (docs/adr/README.md); draft PR lucos#275 awaiting lucas42"
metadata:
  type: project
---

**lucas42 decided "merged means decided"** on lucas42/lucos_worlds#71 (2026-08-06 22:52:43Z), after asking "I don't really see value in a `Status` field living inside the ADR… Could we consider removing the status entirely from our ADR standard?".

Written up as **`lucos` ADR-0014** (`docs/adr/0014-merged-means-decided.md`), **draft PR lucas42/lucos#275**, filed 2026-08-07. `lucos` is unsupervised → draft blocks auto-merge; awaiting lucas42's sign-off, then mark ready, *then* run the code-reviewer loop.

**What it decides:** (1) an ADR on a default branch is an agreed decision, unmerged = proposal; (2) no `Status:` field; (3) supersession is an explicit pointer (`**Superseded by:**`, or a section-level note for partial supersession), not a status word; (4) implementation tracking lives in GitHub issues; (5) the ADR format is written down at **`lucos/docs/adr/README.md`** — normative for *every* lucos repo, and a **living standard** (cosmetic clarifications don't need a new ADR; changing §1–§4 does).

**Why it matters beyond the field:** no document anywhere defined the ADR format. Convention-by-imitation produced 3 spellings of `Status`, 3 title styles, 2 filename widths and 5 names for the discussion-link field across 63 ADRs. Nothing reads ADRs — no template, no linter, no CI check; `lucos_repos` audits 27 conventions and none touch them; every `docs/adr` reference in code is a prose pointer for humans.

**Estate baseline (2026-08-07, from the GitHub trees+contents APIs):** 63 ADRs across 18 active repos — 45 `Accepted`, 18 `Proposed`, 0 without the field. Plus 1 in the archived `lucos_scheduled_scripts` (out of scope). See [[feedback_parse_reference_data_never_handbuild]] for why the earlier local-checkout figure (48/15) was wrong.

**The ADR-0013 reversal — worth remembering, it inverts a widely-repeated claim.** Both `team-lead` and I treated `lucos` ADR-0013 as the counter-example: merged, `Proposed`, unimplemented ⇒ "merged means decided" would decide it by fiat. Wrong. **lucas42 APPROVED lucas42/lucos#237 fifteen minutes before it merged** — the decision *was* agreed; only the build is outstanding (`additionalReviewers` still absent from configy; lucas42/.github#70 + lucas42/lucos_claude_config#114 open). Its `Proposed` line was tracking *implementation*, which is exactly the conflation ADR-0014 removes. Checking every `Proposed` ADR's introducing PR the same way: **14 of 18 carry an explicit lucas42 approval; only 4 merged on a bot approval alone** (`lucos_repos` ADR-0005 + ADR-0007, `lucos_claude_config` ADR-0003, `lucos` ADR-0009). Migration judgement = 4, not 15. Relates to [[reference_adr_status_is_a_claim]].

**Follow-ups filed, all Blocked on lucas42/lucos#275 merging** (merging *is* the ratification):
- lucas42/lucos#276 — remove the field from all 63 ADRs (18 repos, 18 PRs). Body carries the per-repo counts and the three-spellings warning.
- lucas42/lucos#277 — confirm or supersede the 4 ADRs with no recorded human sign-off.
- lucas42/lucos_claude_config#125 — point agent instructions at the standard instead of restating it (architect persona line 71 + the Context-lesson paragraph; `review-pr.md` line 58's "ADR status flip" example becomes impossible).

**Deliberately not done:** a `lucos_repos` convention enforcing the format. Nothing reads ADRs, the harmful drift is removed by design rather than enforcement, and the residual variance is cosmetic — a Go check + tests + an 18-repo rollout to police document cosmetics fails proportionality. Revisit only if `Status` creeps back in by imitation after removal.
