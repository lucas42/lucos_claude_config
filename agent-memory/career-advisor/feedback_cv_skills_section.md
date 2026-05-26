---
name: cv-skills-section
description: Skills section format rules for CV variants — 5 categories target, single-paragraph layout with hard line breaks to remove inter-category spacing
metadata:
  type: feedback
---

When drafting the Skills section of a tailored CV variant:

**Rule 1 — category count**: target **~5 categories** (not 8, not 10). Each category is one bold heading + a comma-separated keyword list. More than ~5 categories starts to take up half a page and stops looking like a quick scan-area for ATS keywords.

**Rule 2 — single-paragraph layout**: structure the Skills section as **one paragraph with hard line breaks between categories** (using pandoc's backslash-line-break: `\` at end of line), not as N separate paragraphs. The default pandoc rendering of separate paragraphs adds paragraph-spacing-after between each category, wasting vertical space; the hard-line-break form gives tight single-line spacing between categories.

**Why:** Stated 2026-05-22 by Luke after a Staff Platform Engineer CV came out at 4 .docx pages — the Skills section was 8 categories rendered as separate paragraphs, taking up nearly half of page 1. Luke called both issues out as the main bloat contributors: too many categories AND the inter-paragraph spacing.

**How to apply:**

1. Before drafting, list the JD's top 5–6 thematic areas and aim for one Skills category per theme. Consolidate adjacent themes (e.g. Cloud + Platform = Platform engineering & cloud; Programming + Data + Engineering practice = Programming, data & engineering practice). Keep Generative AI as its own category whenever AI-assisted coding is a JD signal, since it doesn't bucket cleanly with anything else.
2. Layout in markdown:
   ```markdown
   # Skills

   **Category A** — keyword, keyword, keyword\
   **Category B** — keyword, keyword, keyword\
   **Category C** — keyword, keyword, keyword\
   **Category D** — keyword, keyword, keyword\
   **Category E** — keyword, keyword, keyword
   ```
   Note: backslash at the end of all but the last line. No blank lines between categories. This produces one paragraph in the .docx with hard line breaks between categories — no inter-paragraph spacing.
3. **Don't** use blank lines between categories — that turns each into its own paragraph and re-introduces the spacing bloat.

The freetrade variant (committed 2026-05-21) was written before this rule existed and uses 8 categories with separate paragraphs. It's the previous template that all of `lukeblaney_cv_tailored/orgs/*` derive from. New variants should use the 5-categories + single-paragraph format; do not retro-edit committed variants unless asked.

## Rule 3 — Section labels aren't framing

Stated 2026-05-26.  The Skills section's category labels should be **neutral** — just the discipline name ("Cyber Security", "Engineering Leadership", "Architecture & Distributed Systems").  **Don't** append cover-letter framing as a label suffix.

**Bad**: `**Cyber Security (Engineering-Enablement)**: DevSecOps tooling rollout...`
**Good**: `**Cyber Security**: DevSecOps tooling rollout...`

**Why**: framing belongs in cover-letter prose, where it earns its weight by explaining the angle of the evidence.  In the Skills section it's just label noise — the reader is scanning keywords, not absorbing positioning narrative.  A parenthetical framing on a category label also implies that the underlying skill is somehow qualified or limited (e.g. "this is cyber but only the platform-enablement kind"), which understates the actual experience.

**Triggered by**: 2026-05-26.  I had pasted the "cyber-as-platform-enablement" framing (from `[[user-role-framing]]`) directly into the Cyber Security Skills label.  Luke pushed back: "Stating 'Engineering-Enablement' after Cyber Security is odd: just because we've discussed that as the framing doesn't mean you should go pasting it in the skills section."

**Rule of thumb**: if a category label has a parenthetical, ask whether the parenthetical is *part of the discipline name* (e.g. "Generative AI" is a discipline name; "(Engineering-Enablement)" is framing).  If framing, drop it.  The framing belongs in the cover letter para 2/3 prose.

Related: [[cv-page-count]], [[cv-rebuild]], [[user-role-framing]].
