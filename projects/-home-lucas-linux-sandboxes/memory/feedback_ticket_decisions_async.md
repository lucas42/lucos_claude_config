---
name: Ticket-level decisions belong on the ticket
description: Don't use AskUserQuestion to force synchronous answers on triage-decision routing — use the ticket comments asynchronously and continue dispatching other ready work.
type: feedback
originSessionId: 6ce34597-cfb3-4151-9e30-3c9c944f1aca
---
When a triage routing decision lands on lucas42 (`owner:lucas42` + `status:awaiting-decision`), the venue for that decision is the ticket itself — its comments and reactions. Do NOT also AskUserQuestion to extract a synchronous answer in chat.

**Why:** AskUserQuestion blocks the chat flow until lucas42 answers. Ticket-level design discussions can take time (sometimes hours, sometimes days). Forcing a synchronous response in chat:
- Blocks other actual work from being dispatched
- Duplicates the venue (the question is now in two places)
- Burns lucas42's attention on chat overhead when the ticket already captures the question

**How to apply:**
- After consulting an agent and relaying their recommendation on a ticket, the default is to stop — not to AskUserQuestion.
- The ticket labels (`owner:lucas42` + `status:awaiting-decision`) + the agent's comment are sufficient. Lucas42 will engage when ready.
- Continue dispatching other ready work (dev queue, etc.) in the meantime — one ticket's decision pending does not block other unrelated tickets.
- AskUserQuestion is for **chat-level coordination** (e.g. "which of these four ready issues should I dispatch first?"), not **ticket-level decisions** that have their own venue.
