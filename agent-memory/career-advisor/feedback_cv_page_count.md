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

**Critical:** verify the page count against the **.docx render**, not the LaTeX-PDF render. The .docx is what gets submitted to ATSes — it's the document under the constraint. The LaTeX-PDF (`render-tailored.sh` co-output) is for human review only and uses a different layout engine; its page count can differ from the .docx's by a page or more. Previously the skill verification scripts checked LaTeX-PDF page count, which was wrong: the same source was 3 pages in LaTeX-PDF but 4 pages in .docx (caught after Luke flagged it during a Preply Staff IC tailoring on 2026-05-22).

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
5. If page count = 3: ask Luke whether to keep at 3 or push toward 2. The current page is already at the hard limit, and pushing to 2 may require dropping content (Talks & Panels, multi-bullet roles) that is genuinely strong for the JD — show the trade-off rather than making it unilaterally.

**Related**: [[cv-skills-section]], [[cv-variant-content-rule]], [[cv-rebuild]].
