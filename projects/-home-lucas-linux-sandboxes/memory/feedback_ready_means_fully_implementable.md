---
name: feedback-ready-means-fully-implementable
description: "Status = Ready means the work can be implemented AND merged to a working end-to-end state today; \"unit-testable in parallel against fixtures\" is NOT grounds for Ready"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 95dd3212-10dc-4f8f-9047-e18d6d22e7d3
---

If any cross-repo or in-repo dependency must close before the work can be merged into a working, end-to-end-verifiable state, the issue is **Blocked**, not Ready. Do not mark Ready just because some unit tests can be written against fixture RDF (or any other parallel-implementable carve-out).

**Why:** On 2026-05-18 the architect triaged `lucos_arachne#539` as Ready with the reasoning "code can be written and unit-tested in parallel against fixture RDF; #712 only required for end-to-end testing." `lucos_contacts#712` was still open. The dispatch skill's open-dependency guard caught it, but lucas42's correction was sharper: if real dependencies must land before the work is complete, it's Blocked — full stop. Unit tests against fixtures don't establish that the integration works in production.

**How to apply:** When triaging or approving an issue (or accepting another agent's triage), check every dependency listed in the body or comments. If any is open, the issue is Blocked, regardless of how the body frames parallelisability. Don't accept "can be done in parallel" carve-outs at the Ready/Blocked decision — they belong in the body as implementation notes, not as a status override. See [[feedback-correct-agents]] for the two-message correction sequence when an agent makes this mistake.
