---
name: feedback_report_followups_filed_not_deferred
description: "Report/incident/audit follow-ups needing lucas42's decision are still filed as full-info issues routed Awaiting Decision — never left as unfiled disposition-table lines, and never put to him as a decision off a one-line summary"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c2a277ac-c41c-46d8-a202-07f86f739f5e
---

Follow-up actions surfaced by an incident report, audit, or similar — **even ones that need lucas42's go/no-go** — get filed as full-information GitHub issues (incident/context, root cause, options + tradeoffs) and routed to him for approval via the board (Awaiting Decision; becomes Ready only on his OK). Do NOT leave them as unfiled "deferred to lucas42" lines in a report's follow-up table, and do NOT ask him to make a disposition off a one-line summary.

**Why:** 2026-07-10, two lucos#265 incident-report follow-ups (a cred-gated-deploy guard, a /map 403-vs-302 UX call) were left deferred-unfiled in the follow-up table and I asked lucas42 to decide off those thin lines. He said the report info wasn't enough for a well-informed decision and asked for proper issues with all the relevant information, then routed to him for approval before Ready. Undecided is not a reason to skip filing.

**How to apply:** when a report/audit surfaces follow-ups, ensure each becomes a full-context issue — delegate the drafting to the owning agent (SRE for incident follow-ups per [[feedback_verify_review_on_current_head]]'s sibling process in `incident-reporting.md`; the relevant specialist otherwise) — then board it Awaiting Decision/lucas42. Don't ask him to choose off a summary table. Instruction home: `references/incident-reporting.md` Step 1.3.
