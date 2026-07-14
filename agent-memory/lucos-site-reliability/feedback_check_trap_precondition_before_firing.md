---
name: Check a trap's precondition applies before firing it at a teammate
description: Don't pattern-match a symptom to a known trap and "correct" someone — verify the trap's actual condition holds, and verify the mechanism you're about to assert
metadata:
  type: feedback
---

**Before "correcting" a teammate with a known trap/pattern, check that the trap's *precondition* actually applies to what they said — and verify any mechanism you're about to assert as fact.**

**Why:** 2026-07-14, lukeblaney_co_uk#68. The code-reviewer wrote "`mergeable_state: clean`, `auto_merge: null`, awaiting lucas42's approval to merge." I saw `auto_merge: null`, pattern-matched it to the auto-merge trap in my own `sre-stuck-pr-support.md`, and told them null is meaningless steady-state because "the merge is driven by a CI bot reacting to the approval, not GitHub's native auto-merge." **Both halves were wrong:**

1. **The trap's precondition didn't apply.** The rule is: don't infer ***"needs manual merge" / "stuck"*** from `auto_merge: null`. The reviewer never claimed that — they said "awaiting approval", which on a supervised repo is the *correct* reading. I matched the symptom (`auto_merge: null`) and skipped the condition (a stuck/manual-merge claim).
2. **The mechanism I asserted was unverified and false.** `reusable-code-reviewer-auto-merge.yml@v1.22.0` line 104 runs `gh pr merge --auto --merge` — that IS GitHub-native auto-merge, so `auto_merge` goes non-null exactly when the workflow fires. It's a real signal.

Ground truth for supervised repos (verified from workflow runs on #68): the workflow fires on **every** `pull_request_review: submitted`, checks `unsupervisedAgentCode` via configy, and on a supervised repo declines unless the approver is the expected human. So on a supervised repo `auto_merge` stays null until **lucas42** approves, then the workflow fires and it merges seconds later (09:28:48 reviewer-approval run → declined; 09:31:09 lucas42-approval run → merged; `merged_at` 09:31:22).

So: **`auto_merge: null` on a supervised repo = "the gating approval hasn't landed yet"** — informative, not noise. It only misleads if you read it as "stuck / needs a human to click merge".

**How to apply:** when a teammate's statement trips a pattern you hold, first ask "does the pattern's stated condition actually match their claim, or just its surface symptom?" Then, before asserting the *mechanism* behind your correction, read the thing (workflow file, code, config) — the correction gets relayed as fact into their context and propagates. Wrong corrections are worse than silence: they overwrite a correct heuristic. Cost me nothing to check line 104; would have cost the reviewer a good signal.

**Instruction defect surfaced (flagged to team-lead 2026-07-14):** `agents/sre-stuck-pr-support.md` §"The auto-merge trap" says the workflow "is independent of the PR-level `auto_merge` field (which only reflects GitHub-native auto-merge — it is `null` even when workflow-driven auto-merge is in place)". Given line 104 uses `--auto`, that's false and is what mis-primed me. Accurate wording: `auto_merge` is null *until the gating approval lands and the workflow fires* — so null means "not yet approved", not "stuck".

See also [[feedback-refetch-before-accusing]], [[feedback-verify-permission-claims]], [[feedback-correlation-is-not-confirmed]].
