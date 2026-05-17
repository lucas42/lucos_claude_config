---
name: file-followups-during-design
description: When closing out a design issue that surfaces downstream work in other repos, file the follow-up tickets during the design conversation — never defer
metadata:
  type: feedback
---

When a design issue surfaces follow-up work in other repos (consumer subscriptions, schema changes, new endpoints, etc.), file those tickets **during the design conversation**, not after — even if a dependency hasn't landed yet, even if the consumer is parked, even if implementation can't start.

**Why:** lucas42 explicitly said "I don't trust you lot to remember to file them later." The eolas#19 conversation proved him right — I'd deferred a lucos_photos follow-up pending photos#104, which closed 2 months ago, and I'd forgotten. The deferred ticket was never filed and would have stayed unfiled indefinitely if he hadn't called it out.

**How to apply:**
- Last step before sign-off on any design issue: enumerate every downstream repo touched by the design, file a ticket against each one, link them from the parent issue body.
- "Wait until X lands" is never a reason to defer ticket filing. Filing is cheap; remembering later isn't free.
- If a consumer doesn't currently exist (e.g. an event with no subscriber yet), file the ticket anyway with a note that it sits dormant until needed. The alternative — relying on memory to file later — has a poor track record.
- If a downstream repo genuinely doesn't need a ticket (e.g. lucos_photos storing `contact_id` numeric refs not URIs), say so explicitly in the design comment rather than leaving it ambiguous.
- Surface the analysis to lucas42 so he can correct any miscalls (e.g. "I don't think lucos_photos needs a ticket because X — flag if you'd rather have a placeholder").

See also [[loganne-consumer-test]] — filing the emitter ticket early is fine, but be honest in the design that the consumer doesn't yet exist.
