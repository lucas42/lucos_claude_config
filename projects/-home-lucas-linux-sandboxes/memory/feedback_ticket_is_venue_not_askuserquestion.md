---
name: feedback_ticket_is_venue_not_askuserquestion
description: "When a design discussion lives on a GitHub ticket, don't pull its decisions into AskUserQuestion — lucas42 answers on the ticket"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bbf332f2-a3a1-44cf-9478-3ce93c92883c
---

When a design/consultation discussion is already unfolding on a GitHub ticket (e.g. an architect posting framing + questions as comments), do NOT relay the specialist's decision points back to lucas42 via AskUserQuestion. He will respond **on the ticket** — that's where all the context is.

**Why:** The ticket holds the full context (architect's framing, the eval, the options). Re-asking in the coordinator session forces a synchronous, context-poor answer and duplicates the venue. lucas42 explicitly told me to "stop asking these questions here" (2026-07-07, lucos#248 BookStack decision).

**How to apply:** After a specialist posts questions/options as a ticket comment, tell lucas42 the ball is in his court on the ticket and stop. When he replies there, re-fetch the comment and relay his decision onward. Reserve AskUserQuestion for decisions that have no async venue. Extends [[feedback_ticket_decisions_async]].
