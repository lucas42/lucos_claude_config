---
name: reference-adr-status-is-a-claim
description: "An ADR's Status conflates 'decision agreed' with 'implementation shipped' — check the introducing PR's reviews for the first and the running system for the second; never infer either from the header"
metadata: 
  node_type: memory
  type: reference
  originSessionId: b44602b5-7b75-441e-91ea-9b5854bc5c27
  modified: 2026-08-07T01:06:22.290Z
---

# An ADR's `Status:` is a claim; the PR's reviews and the running system are the proof

**Two different questions live behind that one word, and the header answers neither reliably:**

- **Was the decision agreed?** → read the **introducing PR's review list** for an explicit `lucas42` approval. Not the header.
- **Did the implementation ship?** → check the running system — does the field/endpoint/behaviour exist, are the implementation tickets closed. Not the header.

**The trap:** an ADR's **Context** section describes the status quo the ADR *criticises*. A `Proposed` ADR whose Context matches live behaviour therefore reads as ratified **because the part you recognise is real** — and citing it can put you behind the very arrangement the document argues should be scrapped.

**Worked example, and it inverts twice.** `lucas42/lucos` ADR-0013 (data-driven auto-merge approval policy) reads `Proposed`. Its Context accurately describes the live gate reading `unsupervisedAgentCode`, so it looks implemented — it isn't: its `additionalReviewers` field is absent from `configy.l42.eu`, and `lucas42/.github#70` / `lucas42/lucos_claude_config#114` are open. But it does **not** follow that the decision was open: lucas42 **approved** the introducing PR `lucas42/lucos#237` at 01:13:54Z on 2026-06-11, fifteen minutes before it merged. The `Proposed` line was tracking *implementation*, not *agreement*. Both the coordinator and `lucos-architect` got this wrong in the same evening, in both directions, from reading the header and the Context and never the PR.

**Do not infer "Proposed means not yet decided."** Across the estate, **14 of 18** `Proposed` merged ADRs carry an explicit lucas42 approval on their PR; only 4 lack one. Estate figures (GitHub API, 2026-08-07): **63 ADRs, 18 repos, 45 `Accepted`, 18 `Proposed`, 0 without the field.** Earlier counts of 48/15 came from local checkouts that double-counted a mirrored clone and missed `lucos_claude_config` — don't re-propagate them.

**Superseded going forward:** `lucos` ADR-0014 ("merged means decided") removes the field entirely; `lucas42/lucos#276` strips it from all 63 files. Once that lands, presence on a default branch *is* the status and this whole class of misreading goes away. Until then, and for any archived copy, use the two-question check above. Relates to [[feedback_verify_before_propagating]] and [[feedback_treat_empty_tool_output_as_unknown]].
