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
3. Look for **continuity arguments** that link the older story to more recent work:
   - Roles where the older work's responsibilities continued under a different title (e.g. architectural decision-making continued as part of the Principal Engineer remit after the Architect titles were phased out at the FT).
   - Ongoing maintenance / evolution of the same systems.
   - Carried-forward architectural decisions or standards.
   - "Unbackfilled" responsibilities pattern: the role formally moved on but specific responsibilities stayed with the same person.
4. **Worked example (the corrected pattern, after 2026-05-22 sharpening — see [[user-role-framing]]):** the FT Architect-titles-phased-out → PE-remit continuity is fine to *use* as a private continuity argument, but **only surface the explicit "phased-out" / "absorbed" language in CV/letter copy for Architect-titled JDs**. For non-Architect-titled senior IC variants (Staff / Principal / Platform Engineer with architecture expectations), state the continuity plainly without explaining the transition: "the Principal Engineer remit included system-architecture responsibility alongside engineering leadership", and let the Summary anchor on "a decade of architecture and platform-engineering work at the Financial Times" without elaborating on title changes.
5. **Where the continuity framing lands**:
   - Architect-titled JDs: Summary opening line (continuous-arc framing with the title transition explained), PE entry lead bullet (the "absorbed-into-PE" claim), letter para 2 (story bridges through the transition).
   - Non-Architect senior IC JDs: Summary opening line anchors on "a decade of architecture and platform-engineering work" without explaining title transitions; PE entry lead bullet states architectural responsibility plainly as part of the remit; letter para 2 (if applicable) bridges through the work, not through the org reshuffle.

**Adjacent**: the same general principle applies to **management-track** variants, but with less urgency — hiring managers reading Director / Head / VP of Engineering JDs are more willing to accept older architecture exposure as a credential, as long as the *leadership* track has been continuous.

Related: [[user-role-framing]], [[user-cover-letter-patterns]], [[overlap-years-claim]].
