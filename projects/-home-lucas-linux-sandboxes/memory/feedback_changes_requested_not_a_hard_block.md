---
name: feedback-changes-requested-not-a-hard-block
description: A CHANGES_REQUESTED review only hard-blocks a merge if the repo enforces required-review branch protection; the reliable structural block is converting the PR to draft
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1a322f6a-b1ba-45ab-8435-5406ebc4888e
---

A `CHANGES_REQUESTED` review does **not** reliably block an auto-merge. It only hard-blocks if the repo enforces **required-review branch protection** — and lucos repos vary, with the agent Apps getting **403 on the protection endpoint**, so you usually can't confirm it's enforced. The lucos "supervised" gate is the **auto-merge workflow's reviewer-identity check** (`reusable-code-reviewer-auto-merge.yml` runs `gh pr merge --auto` only when the approver is `lucas42` for `unsupervisedAgentCode=false`); `--auto` waits only on *branch-protection* conditions, so if no review is required there, an approval merges the PR **regardless of any standing CHANGES_REQUESTED**.

**Tell:** with a CHANGES_REQUESTED standing and the deciding approval not yet given, `mergeable_state == "clean"` (rather than `"blocked"`) means there is **no** required-review protection — the review is advisory only.

**The only reliable structural block** before a fix lands is converting the PR to **draft** (auto-merge can't fire on a draft). A review is a visible warning, not a lock.

**Why:** 2026-06-25 — on seinn#522 (an imminent SW hard-break) I told lucas42 the architect's CHANGES_REQUESTED would "hard-block" the merge (over-applying the #211 lesson). The architect checked and corrected it: seinn has no required-review protection, so only lucas42 *not approving* (the human hold) or a draft conversion would actually block it. It resolved fine because the fix landed and was re-approved before he approved — but the "review hard-blocks" claim was wrong.

**How to apply:** Don't tell lucas42/teammates a CHANGES_REQUESTED "hard-blocks" / "locks" a PR unless required-review branch protection is confirmed. To genuinely hold a PR from auto-merge before a fix is in, convert it to **draft** (the author/architect can do this) — and rely on the human hold as backup, not the other way round. Relates to [[hedge-unverified-claims]] — I asserted a structural guarantee I hadn't verified.
