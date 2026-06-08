---
name: red-means-down-no-ack-state
description: lucas42 principle — a red monitoring check correctly means "down"; no ack/known-issue board state; fix the problem, board self-clears, why-trail lives on the ticket
metadata:
  type: feedback
---

Don't propose (or build) an "acknowledged / known-issue / mute" board state for monitoring. lucas42 **declined `lucos_monitoring#276`** (closed not_planned, 2026-06-08) on a firm operational-hygiene position:

- A red check **correctly** means "this is down." It makes **no claim** the outage is *fresh* — "fresh" is the viewer's inference, not something the board asserts. So "the board can't tell known-red from fresh-red" is NOT a real gap.
- An ack/known-issue state invites poor hygiene ("ack and forget"). The right way to turn a check green is to **fix the underlying problem**, not mask a genuine outage from view.

**Why:** keeps the board truthful and pressure on real fixes; avoids a graveyard of stale acks.

**How to apply:** for a known-pending issue (e.g. `backups/fetch-info` red while awaiting the [[firewall-rollout]] bridge fix lucos_backups#307), the board **stays red** until the fix lands and it self-clears. The durable "why" trail lives on the **relevant ticket** (a factual issue comment), NOT on the board. My own **sentinel** distinguishing known-vs-new for *my* alerting is still fine — that's separate from the shared board. Carry this forward when framing similar future requests: don't pitch board-level muting/ack/maintenance-badge features. (Related: [[monitoring-suppress-is-deploy-window-only]] — `/suppress` also can't do this, by design.)
