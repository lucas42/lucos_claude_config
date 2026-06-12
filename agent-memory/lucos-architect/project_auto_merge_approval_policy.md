---
name: auto-merge-approval-policy
description: lucos ADR-0013 — data-driven auto-merge required-reviewer policy (configy additionalReviewers + workflow enforcement)
metadata:
  type: project
---

# Data-driven auto-merge approval policy — lucos ADR-0013

**Status (2026-06-11):** **Accepted** — lucas42 approved PR lucas42/lucos#237 unconditionally (ratifies ADR as written, incl. supervised-requires-both + auth_scopes-deferred). PR marked ready. Originating ticket: lucos_configy#224. **Impl follow-ups raised (dependency-ordered):** lucos_configy#231 (field, Ready) → lucas42/.github#70 (workflow enforce, blocked on #231 deploy) → lucos_claude_config#114 (instruction→configy lookup, blocked on #70).

**Gotcha for impl:** lucos is unsupervised → auto-merge fires on the **bot's** approval, not lucas42's; lucas42's approval alone does NOT trigger the unsupervised path, and marking-ready fires no review event. PR #237 needs lucos-code-reviewer to review before it merges. **#114 nuance:** "drop the static list" = replace hardcoded list with a configy `additionalReviewers` *lookup* — the agent must still REQUEST the declared reviewers (else workflow blocks merge with nobody invited).

**Why:** lucas42 (configy#224, 2026-06-11) wants the per-repo required-reviewer policy moved out of `lucos-code-reviewer`'s instructions into `lucos_configy`, enforced by the auto-merge GitHub Action rather than the agent.

**Home rationale:** a `lucos` *estate* ADR, NOT a configy ADR — spans configy schema + `.github` auto-merge workflow + code-reviewer instructions. Analogous to ADR-0007 (estate policy carried by configy fields, enforced elsewhere). Configy is one implementation surface, not the home of the decision.

**The decision (3 parts):**
1. configy gains per-repo `additionalReviewers` (semantic names list, e.g. `lucos-security`; default `[]`; on System/Component/Script, mirroring `unsupervisedAgentCode`; camelCase serde rename; must update `all.rs` RDF too; always-present array per configy's null/empty contract). Populate `[lucos-security]` on firewall/creds/aithne.
2. Auto-merge workflow computes required set = always code-reviewer; +lucas42 if `unsupervisedAgentCode==false`; +each additionalReviewer. Evaluates **latest review per required approver** (order-independent). Verifies login **and** numeric id; name→(login,id) map lives in the **workflow** not configy (enforcement detail; keeps configy semantic). **Fails closed** on unreachable/absent-field/unmappable-reviewer.
3. code-reviewer drops the static security-critical list; keeps the *subjective* per-PR specialist judgement (enforced by withholding its own always-required approval).

**Key consequence:** supervised repos now need BOTH bot + lucas42 (today they merge on lucas42 alone). Manual UI merge still bypasses — tightens *auto*-merge only.

**Open questions to lucas42 (on the PR):** the supervised-requires-both tightening; whether `lucos_auth_scopes` should carry `lucos-security` or rely on its existing supervised gate.

**Deferred follow-ups (raise once Accepted, NOT before — design still open):** configy field impl; `.github` workflow rewrite + smoke tests; `lucos_claude_config` review-pr list removal. Enumerated in the ADR's Deferred Work section. See [[feedback_file_followups_during_design]] — held deliberately because the design is genuinely unsettled, not forgotten.

**Self-authored-PR deadlock (design check 2026-06-12, .github#70 comment 4689633805):** #70's "latest review from EVERY required approver = APPROVED, fail-closed" check **deadlocks forever** when a required approver is also the PR author — GitHub structurally blocks self-approval, so that approver's latest review can only ever be COMMENTED, never APPROVED. Verified against live lucas42/lucos_aithne#98 (security[bot]-authored on unsupervised always-security aithne; security's latest review = COMMENTED; merged ONLY because today's workflow checks the single triggering reviewer — the exact gap #70 closes). **Fix = exclude the PR author from the required set** (named-approver analogue of GitHub's no-self-approval), + 2 guards: (a) fail closed if exclusion empties the set (e.g. code-reviewer authors on a no-additional-reviewer repo), (b) log each exclusion loudly. NOT a new trust mechanism — ADR-0013 pt 3 already makes code-reviewer's always-required APPROVED the carrier of specialist sign-off, and review-pr.md already has code-reviewer withhold approval until security's self-sign-off comment is present; workflow trusts that APPROVED as proxy. **Advised AGAINST** the YAML parsing approving comment-text (fragile/spoofable; judgment belongs in the agent). **SETTLED 2026-06-12:** lucas42 chose (i) accept self-sign-off, + hard red line verbatim: "every PR needs at least one approver who didn't raise the PR ... a hard check ... we don't end up with an empty set." **Author-exclusion rule + empty-set fail-closed hard check + 2 acceptance criteria + smoke-test coverage now folded into #70 body (updated 09:37Z) + summary comment 4689713872.** #70 back to Blocked on lucas42/lucos_configy#231 for impl (owner=developer). (Prior open Q was: (i) vs (ii) escalate security-authored security-critical PRs to lucas42 — he picked (i).)

Related: [[reference_info_endpoint_network_only]], auto-merge mechanics in MEMORY.md "Auto-merge & security checks".
