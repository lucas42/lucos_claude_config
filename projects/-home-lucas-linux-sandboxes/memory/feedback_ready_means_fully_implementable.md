---
name: feedback-ready-means-fully-implementable
description: "Status = Ready/Blocked is about whether the integration is end-to-end-verifiable today, NOT just whether a named dep is open. Distinguish 'dep gates the integration' (Blocked) from 'dep gates the data the integration will find' (not Blocked — ship as dormant code)."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 95dd3212-10dc-4f8f-9047-e18d6d22e7d3
---

A named dependency is a Blocker when **its closure is required for the work's integration to be verifiable end-to-end**. If the dep just provides *data* that the work-once-deployed will eventually act on — and the work is correct as a no-op when that data isn't present yet — it is **not** a blocker. Such work can ship as dormant code.

**Two cases — only the first is Blocked:**

1. **Dep gates the integration.** Without the dep, the work cannot produce its correct end-to-end behaviour even with the right data — the integration itself depends on the dep landing (a new API endpoint, a new event type, a new schema field, a new contract). → **Blocked**.
2. **Dep gates the data the integration will find.** Without the dep, the work's deployed behaviour is a correct no-op (e.g. `WHERE x = old` finds zero rows; webhook arrives, handler runs, nothing to update). Once the dep populates data, the work activates automatically. → **NOT Blocked** — ship as dormant code.

Do **not** mark Ready just because some unit tests can be written against fixture data — that test doesn't distinguish case 1 from case 2. Do **not** mark Blocked just because a dep is named in the body — a "depends on" that turns out to be data-only is fine to ship.

**Why:**
- **2026-05-18 (`lucos_arachne#539`):** architect triaged Ready with "can be unit-tested in parallel against fixture RDF; #712 only required for end-to-end testing." lucas42 corrected: the integration itself needed `lucos_contacts#712` to land — fixture-only testing didn't establish production correctness. Case 1; really Blocked. (Original learning that gave rise to this rule.)
- **2026-05-27 (`lucos_media_metadata_api#236`):** coordinator left Blocked because `#237` (Person-tag migration) was open. lucas42 corrected: `#237` just populates data; `#236`'s webhook handler is a correct no-op against an empty `WHERE uri = old` lookup, and its loganne integration is fully testable today. Case 2; not actually Blocked. (Refinement showing the rule was over-applied.)

**How to apply:** For each named dependency, ask: *if the work shipped today, would its end-to-end behaviour be correct given current data?*
- **Yes** (correct empty-result no-op, or no relevant data exists for the work to operate on): NOT Blocked. Ship as dormant code; it activates as the dep populates state.
- **No** (the integration itself isn't verifiable, or the work would silently misbehave): Blocked.

Quick disambiguators:
- "Once the dep ships, my code starts doing something" → likely case 2; not Blocked.
- "Once the dep ships, my code becomes correct" → case 1; Blocked.
- "I need fixture data to even unit-test this" → fixtures aren't the criterion; ask the integration question instead.

See [[feedback-correct-agents]] for the two-message correction sequence when an agent makes this mistake.
