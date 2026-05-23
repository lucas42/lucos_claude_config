---
name: cv-page-count
description: CV page count rules for variants — hard limit 3 pages, target ~2 pages, and verify against the .docx (not the LaTeX-PDF)
metadata:
  type: feedback
---

When generating a tailored CV variant for Luke:

**Hard limit**: 3 pages.
**Target**: as close to 2 pages as the content will sensibly allow.

**Why:** Stated 2026-05-22. Luke wants tailored CVs to err on the side of being shorter and more scannable rather than maximally informative. 4 pages is unsubmittable; 3 is the absolute ceiling; 2 is what to aim for when the content allows it.

**Critical:** verify the page count against the **.docx render**, not the LaTeX-PDF render. The .docx is what gets submitted to ATSes — it's the document under the constraint. The LaTeX-PDF (`render-tailored.sh` co-output) is for human review only and uses a different layout engine; its page count can differ from the .docx's by a page or more. Previously the skill verification scripts checked LaTeX-PDF page count, which was wrong: the same source was 3 pages in LaTeX-PDF but 4 pages in .docx (caught after Luke flagged it during a Staff IC tailoring on 2026-05-22).

**How to apply:**

1. After `render-tailored.sh` produces the .docx, convert it to PDF via LibreOffice in docker:
   ```bash
   DIR="<role-slug-directory>"
   docker run --rm -v "$DIR:/data" --entrypoint /bin/bash linuxserver/libreoffice:latest \
     -c "libreoffice --headless --convert-to pdf --outdir /tmp '/data/Luke Blaney - CV.docx' >/dev/null 2>&1 && cp '/tmp/Luke Blaney - CV.pdf' '/data/Luke Blaney - CV (from docx).pdf'"
   ```
2. Count pages on the resulting `Luke Blaney - CV (from docx).pdf` using pdfminer — that's the .docx's true page count for submission purposes.
3. Add `Luke Blaney - CV (from docx).pdf` to `.gitignore` — it's a verification artefact, not a deliverable.
4. If page count > 3: propose cuts and re-render before showing Luke the result. Pursue the standard cuts first ([[cv-variant-content-rule]], drop Talks & Panels, drop Publications, trim oldest-role bullets) before touching senior-role content.
5. If page count ≤ 3: proceed without asking. 3 is within the hard limit and Luke has already stated 3 is acceptable; don't make him re-confirm it on every variant. 2 is a target, not a gate. Stated 2026-05-23 after I asked Luke to choose between 3 and 2 on a senior IC variant and he flagged that the question was unnecessary.

**Advisory — headless render can be off-by-one vs other word-processors.** Observed 2026-05-23 on a developer-platform Staff IC variant: the same `.docx` rendered as 3 pages in headless LibreOffice (the rule's authoritative measure) but 4 pages in Apple Pages 15.2.1, with the Publications section spilling onto the extra page. Cutting Publications brought Pages's view down to 3 pages while headless stayed at 3. Microsoft Word may behave similarly to Pages (untested).

This doesn't change the rule (≤ 3 in headless = ship without asking), but it's worth knowing that what Luke sees in his viewer and what a recruiter sees in Word may exceed the headless count by a page. Variants where headless shows content well-distributed across page 3 are higher-risk for off-by-one spill than variants where page 3 is sparsely filled. If Luke flags a discrepancy after shipping, the first cut to consider is the Publications section (lowest content-relevance) — it tends to be the section that spills.

**Related**: [[cv-skills-section]], [[cv-variant-content-rule]], [[cv-rebuild]].
