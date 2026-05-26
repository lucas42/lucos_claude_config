---
name: cv-variant-content-rule
description: How to decide which Earlier Career / Positions of Responsibility entries to include in a CV submission variant
metadata:
  type: feedback
---

When generating a role-specific submission variant of Luke's CV from `cv-extended.md`:

**Default rule:** drop the `# Earlier Career` and `# Positions of Responsibility` sections from the submission variant. They dilute the senior-leadership pitch with content from 20+ years ago.

**Contextual exception:** if an entry in those sections is *directly relevant to the target employer or industry*, pull just that entry forward into the variant. Worked example from Luke (2026-05-19): when applying for a tech role at Sainsbury's, he mentioned the Customer Services Assistant role (May–Dec 2005) on the basis that "I'd worked on the tills before to demonstrate I had some sort of understanding of the company/industry".

**Always:** keep both sections intact in `cv-extended.md`. It's the source of truth and may be the only place where this history is recorded.

**Why:** Stated 2026-05-19. Recruiter time-to-skim is short; everything that doesn't actively support the pitch is noise. But context can rehabilitate seemingly-irrelevant entries — work-at-this-employer-before is a powerful signal in a competitive funnel.

**How to apply:** When asked to produce a `cv-{role}.md` variant, scan `# Earlier Career` / `# Positions of Responsibility` for any entry that connects to the target employer or industry. Include those; drop the rest. If unclear, ask Luke.

## Don't delete role sections that create chronological gaps

Stated 2026-05-26.  In-CV `# Employment` role entries (titled FT roles in `cv-extended.md`) should NOT be deleted from a variant just to save page space — deleting a role leaves an unexplained gap in the chronology that recruiters read as suspicious.

**Rule**: compress in place; don't delete.  If a role is too old or off-topic for the JD to justify its full footprint, compress to a minimal entry — role title + dates + one-paragraph description, no bullets — but keep the entry present so the chronology is unbroken.

**Triggered by**: 2026-05-26.  I dropped the Platform Architect - Operational Intelligence role entirely from an advisory-consultancy variant to save page space, creating an unexplained ~14-month gap between Architect - Content (Oct 2016 - Feb 2018) and Integration Engineer (Jan - Nov 2015).  Luke flagged it: "Removing the Operational Intelligence section entirely makes it look like I've unexplained gap on my CV."

**Applies to**: every titled role in cv-extended.md's `# Employment` section.  Earlier Career one-liners and Positions of Responsibility are out-of-scope for the gap rule — they're already at the "trivially droppable" end of the spectrum and pre-date the Employment chronology proper.

**Compression playbook for a role you'd otherwise drop**:
- Role title + dates (always)
- One-paragraph description (preserve the role-shape signal in 2-3 lines)
- Drop all bullets
- Net footprint: ~4 lines vs ~10-15 for a full entry

Related: [[cv-page-count]], [[cv-rebuild]], [[cv-copy-editing-scope]].
