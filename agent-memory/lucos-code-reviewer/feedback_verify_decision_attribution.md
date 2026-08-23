---
name: feedback-verify-decision-attribution
description: quote/verify a cited decision's actual text before crediting it as the authority for a scope call in a review
metadata:
  type: feedback
---

Before writing "the coordinator's triage decision already settled X" (or citing any other party's decision as the authority for a scope call) in a durable review body, quote the decision text itself and confirm it actually says X — don't infer it from how the PR frames what it settled.

**Why:** lucos_agent PR #77 review wrote "the coordinator's triage decision on #75 explicitly settled that split already" for excluding `tests/verify-teammate-quote`. Re-checking the actual Decision block on #75 showed it only settled refactor-vs-no-refactor (the `get-issues-for-triage` heredoc refactor and a regression test were ruled out of scope) — it never mentioned which of the two named test scripts to wire up. The exclusion was `lucos-system-administrator`'s own evidence-based call, made mid-implementation and flagged on the issue at a specific timestamp, then carried into a follow-up issue (#76). Misattributing it to a pre-existing decision made a deviation discovered during implementation look pre-authorised, made #75's still-unticked acceptance criterion look consciously settled rather than changed, and moved credit for a good call away from the person who made it. team-lead caught it and asked for a correction (posted as a follow-up PR comment, since I can't edit a submitted review body) plus this instruction.

**How to apply:** this is a specific instance of [[review_verify_absence_before_requesting]]'s and the "Verify external state before speculating" section's general discipline (see `agents/lucos-code-reviewer.md`) — extended to attributing authority for a scope decision, not just external system state (tags, CI, issue open/closed). The tell to watch for: writing "X already settled this" about a decision you did not make and have not re-read in that turn. Fix: fetch the decision text (issue body / triage comment), quote or closely paraphrase it, and confirm it covers the specific point being attributed — don't let the PR's own framing ("per the triage decision") substitute for reading the decision.
