---
name: check-evidence-recency
description: For senior IC variants, always check the recency of the headline evidence story. Flag the recency objection proactively before showing Luke a draft.
metadata:
  type: feedback
---

For senior IC roles (Staff Engineer, Principal Engineer, Architect, Staff+, IC-track Director-equivalent), hiring managers want to see current architectural muscle. The recency of evidence matters MORE than its impressiveness. A 10-year-old architecture story risks reading as "they used to do this but moved into management" no matter how strong the story was at the time.

**Rule**: Before showing Luke a proposed CV / cover-letter draft for a senior IC role, scan the proposed evidence stories and calculate the years-since-story against the current date. If the headline story is **≥5 years old**, FLAG IT proactively and look for bridges before Luke has to.

**Why**: Stated 2026-05-21 by Luke during a Staff Backend SWE consultation at a retail-investing fintech (Acme Invest). I proposed UPP (an 8-year-old story) as the primary evidence without realising hiring managers might discount it as too old. Luke had to surface the recency concern himself, asking "is it worrying that it was so long ago?" The right response was the Architect→PE absorption bridge (see [[user-role-framing]]) — which brought the architecture story forward by 4 years and rebutted the recency objection inside the document itself. Same issue applied to an earlier hospitality-marketplace Staff IC variant; I had let UPP carry too much load there too without surfacing the recency concern. This is a recurring blindspot, not a one-off.

**How to apply**:

1. When proposing evidence stories for a senior IC variant, calculate "years since story" against today's date.
2. If headline story is ≥5 years old, surface it explicitly: "this story is from {N} years ago — could read as too old for a Staff IC role. Possible bridges:..."
3. Look for **absorption / continuity arguments** that link the older story to more recent work:
   - Roles where the older work's responsibilities continued under a different title (e.g. Architect role formally ended but architectural decision-making absorbed into Principal Engineer remit).
   - Ongoing maintenance / evolution of the same systems.
   - Carried-forward architectural decisions or standards.
   - "Unbackfilled" responsibilities pattern: the role formally moved on but specific responsibilities stayed with the same person.
4. **Worked example**: the Architect→PE absorption pattern (see [[user-role-framing]]). When Luke's Architect-Content role formally ended in Feb 2018, the architectural decision-making didn't stop — it was absorbed into the Principal Engineer remit and continued for another four years across reliability engineering, observability, edge delivery and cyber security.
5. **The framing belongs in three places** in the rendered documents: Summary opening line (continuous-arc framing), the collapsed PE entry's lead bullet (explicit absorption claim), and letter para 2 (story bridges from older anchor through to recent work).

**Adjacent**: the same general principle applies to **management-track** variants, but with less urgency — hiring managers reading Director / Head / VP of Engineering JDs are more willing to accept older architecture exposure as a credential, as long as the *leadership* track has been continuous.

Related: [[user-role-framing]], [[user-cover-letter-patterns]], [[overlap-years-claim]].
