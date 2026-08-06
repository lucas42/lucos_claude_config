---
name: reference-adr-status-is-a-claim
description: "An ADR's Context describes the status quo it criticises, so a live mechanism found there is not evidence the ADR is implemented — check the Decision and whether its implementation shipped"
metadata: 
  node_type: memory
  type: reference
  originSessionId: b44602b5-7b75-441e-91ea-9b5854bc5c27
  modified: 2026-08-06T22:18:26.996Z
---

# An ADR's `Status:` is a claim; its Decision plus shipped implementation is the proof

When citing a lucos ADR, **read the Decision section and check whether it actually shipped** — does the field/endpoint/behaviour it specifies exist, are its implementation tickets closed. Do not rely on the `Status:` line, and do not infer ratification from recognising the mechanism described.

**The trap:** an ADR's **Context** describes the status quo the ADR *criticises*. A `Proposed` ADR whose Context matches live behaviour therefore reads as ratified **because the part you recognise is real** — and citing it can put you behind the very arrangement the document argues should be scrapped.

**Worked example:** `lucas42/lucos` `docs/adr/0013-data-driven-auto-merge-approval-policy.md` is `Proposed` and **correctly so**. Its Context accurately describes the live auto-merge gate reading `unsupervisedAgentCode`; its Decision proposes an `additionalReviewers` field in `lucos_configy` that does **not** exist (`configy.l42.eu/repositories/{repo}` returns no such key), with implementation tickets `lucas42/.github#70` and `lucas42/lucos_claude_config#114` still open.

**How to apply:** anchor an argument on the running control (workflow, config value, live probe), not on the document. Both the coordinator and `lucos-architect` cited ADR-0013 as live in one evening from reading only its Context. Note also that `Proposed` is often *deliberate*, not drift — `lucos` runs 10 of 13 `Accepted`, so a `Proposed` ADR there usually means genuinely-not-yet-decided. Relates to [[feedback_verify_before_propagating]] and [[feedback_treat_empty_tool_output_as_unknown]].
