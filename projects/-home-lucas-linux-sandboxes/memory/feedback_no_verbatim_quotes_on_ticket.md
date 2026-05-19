---
name: feedback-no-verbatim-quotes-on-ticket
description: "Triage-decision comments on the ticket should be brief and reference the prior comment by position, not quote it verbatim — anyone reading the thread can see the prior comment directly"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 43800831-9ee6-4716-b001-e07766f613bc
---

When posting a triage-decision comment on a GitHub issue (re-triage, status transition, routing to a specialist), **do not quote the comment that triggered the re-triage verbatim back on the same ticket**. Anyone reading the issue can already see the prior comment directly above mine; the quote duplicates information without adding any. It also implies the next reader (the architect, the developer) can't be trusted to scroll up — which is condescending.

**Why:** On 2026-05-19, during a triage pass that surfaced `lucas42/lucos_media_metadata_api#237` and `#240`, I posted re-triage comments that quoted lucas42's latest comment verbatim, e.g.

> Re-triaged: Status = Ideation, Owner = lucos-architect.
>
> lucas42 is now questioning the underlying value — quoting his last comment verbatim:
>
> > This now seems like an awful lot of work just to figure out if an artist is a Person or a Group...

lucas42 asked: "Are you worried that architect can't read my comment for some reason?" The verbatim quote on the ticket was pure noise — the architect, when they look at the issue, will see lucas42's comment directly anyway.

**How to apply:** The triage-decision comment on the ticket exists for two reasons:

1. To clear the re-triage flag (any `lucos-issue-manager[bot]` comment does this).
2. To record the project-board change for anyone reading the thread later.

It should be short and reference the prior comment by position ("addressing lucas42's latest comment"), not by quotation. **Verbatim quoting belongs in SendMessage to the specialist** — they don't see the ticket thread in their inbox and need the full quote to act on. Different audience, different content. See [[feedback-no-options-in-consultations]] for the related rule about not adding my own option lists to specialist consultations.