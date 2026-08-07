---
name: adr-standard
description: "lucos ADR-0014 — merged means decided, no Status field, and the first written ADR format standard at lucos/docs/adr/README.md; MERGED 2026-08-07"
metadata:
  type: project
---

**lucas42 decided "merged means decided"** on lucas42/lucos_worlds#71 (2026-08-06 22:52:43Z), after asking "I don't really see value in a `Status` field living inside the ADR… Could we consider removing the status entirely from our ADR standard?".

**MERGED 2026-08-07** — `lucos` ADR-0014 (`docs/adr/0014-merged-means-decided.md`) + the standard at `docs/adr/README.md`, via lucas42/lucos#275, merge commit `48db014`. Under §1 the merge *is* the ratification.

**Observed timeline, worth keeping — it's the draft/ready sequence confirmed rather than inferred:** lucas42 APPROVED 00:58:35Z while still draft (workflow's identity check *skipped*, nothing spent) → marked ready ~01:04Z → `lucos-code-reviewer[bot]` APPROVED 01:05:17Z → **merged 01:05:29Z, 12s later**. So on an unsupervised repo the bot approval on the *ready* head is the trigger, and a human approval on a draft is harmless. Note this still does **not** test the case my persona flags as documented-not-observed: a *bot* approval on a still-draft PR. That remains untested.

**Estate-rollout routing trap, caught before it fired (2026-08-07).** The coordinator initially routed lucas42/lucos#276 via `/estate-rollout`. That skill is built around a **`lucos_repos` convention** — Step 1 is "update or create the convention", Step 2 gates on the dry-run diff and says to stop if absent. #276 has no convention, so neither step can run. Worse than a stall: an agent satisfying Step 1 literally would *build* an ADR-format convention — the option ADR-0014 rejects by name — with the ADR's own follow-up as warrant. Root cause: `/dispatch`'s routing rule defines an estate rollout by **shape** (same change, many repos) while `/estate-rollout` is built on a **mechanism**; they coincide for every rollout run to date. Coordinator corrected the skill (`51ba545`). **Generalise: before routing to a skill, read its Steps, not its description — "no convention involved" is a routing constraint, not a scoping aside.**

**What it decides:** (1) an ADR on a default branch is an agreed decision, unmerged = proposal; (2) no `Status:` field; (3) supersession is an explicit pointer (`**Superseded by:**`, or a section-level note for partial supersession), not a status word; (4) implementation tracking lives in GitHub issues; (5) the ADR format is written down at **`lucos/docs/adr/README.md`** — normative for *every* lucos repo, and a **living standard** (cosmetic clarifications don't need a new ADR; changing §1–§4 does).

**Why it matters beyond the field:** no document anywhere defined the ADR format. Convention-by-imitation produced 3 spellings of `Status`, 3 title styles, 2 filename widths and 5 names for the discussion-link field across 63 ADRs. Nothing reads ADRs — no template, no linter, no CI check; `lucos_repos` audits 27 conventions and none touch them; every `docs/adr` reference in code is a prose pointer for humans.

**Estate baseline (2026-08-07, from the GitHub trees+contents APIs):** 63 ADRs across 18 active repos — 45 `Accepted`, 18 `Proposed`, 0 without the field. Plus 1 in the archived `lucos_scheduled_scripts` (out of scope). See [[feedback_parse_reference_data_never_handbuild]] for why the earlier local-checkout figure (48/15) was wrong.

**The ADR-0013 reversal — worth remembering, it inverts a widely-repeated claim.** Both `team-lead` and I treated `lucos` ADR-0013 as the counter-example: merged, `Proposed`, unimplemented ⇒ "merged means decided" would decide it by fiat. Wrong. **lucas42 APPROVED lucas42/lucos#237 fifteen minutes before it merged** — the decision *was* agreed; only the build is outstanding (`additionalReviewers` still absent from configy; lucas42/.github#70 + lucas42/lucos_claude_config#114 open). Its `Proposed` line was tracking *implementation*, which is exactly the conflation ADR-0014 removes. Checking every `Proposed` ADR's introducing PR the same way: **14 of 18 carry an explicit lucas42 approval; only 4 merged on a bot approval alone** (`lucos_repos` ADR-0005 + ADR-0007, `lucos_claude_config` ADR-0003, `lucos` ADR-0009). Migration judgement = 4, not 15. Relates to [[reference_adr_status_is_a_claim]].

**Follow-ups filed, all Blocked on lucas42/lucos#275 merging** (merging *is* the ratification):
- lucas42/lucos#276 — remove the field from all 63 ADRs (18 repos, 18 PRs). Body carries the per-repo counts and the three-spellings warning.
- lucas42/lucos#277 — confirm or supersede the 4 ADRs with no recorded human sign-off.
- lucas42/lucos_claude_config#125 — point agent instructions at the standard instead of restating it (architect persona line 71 + the Context-lesson paragraph; `review-pr.md` line 58's "ADR status flip" example becomes impossible).

**Deliberately not done:** a `lucos_repos` convention enforcing the format. Nothing reads ADRs, the harmful drift is removed by design rather than enforcement, and the residual variance is cosmetic — a Go check + tests + an 18-repo rollout to police document cosmetics fails proportionality. Revisit only if `Status` creeps back in by imitation after removal.
