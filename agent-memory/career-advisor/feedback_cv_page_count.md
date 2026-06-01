---
name: cv-page-count
description: CV page count rules for variants — hard limit 3 pages, target ~2 pages, and verify against the .docx (not the LaTeX-PDF)
metadata:
  type: feedback
---

When generating a tailored CV variant for Luke:

**Hard limit**: 3 pages **as the recipient sees it** (Microsoft Word / Apple Pages) — NOT the headless LibreOffice count, which under-counts by up to a page (see the Word/Pages margin rule below).
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
5. **headless ≤ 2 pages: ship it.** 2 is the target and safe against the Word/Pages margin below.
6. **headless = 3 pages: do NOT auto-ship — apply the +1 margin.** The headless round-trip under-counts the recipient's Word / Pages view by up to ~1 page (see margin rule below), so headless-3 is the danger zone. Inspect the page-3 fill: *sparse* spillover (a stray Education line, one or two Talks entries — Luke: "spilling a bit into the third page is fine ... shouldn't be treated the same as a jam-packed page 3", 2026-05-26) is genuinely 3 pages in Word and acceptable; a *near-full / jam-packed* page 3 will almost certainly be 4 pages in Word — trim toward 2 (surgical line-wrap-orphan rewording first, then cuts) before shipping. If it genuinely can't be cut, ship but flag to Luke that it may render as 4 pages in his viewer.
7. **headless ≥ 4 pages: unsubmittable.** Cut and re-render before showing Luke.

**Cutting technique — prefer surgical word-edits over section-deletions.**  Stated 2026-05-26 after I dropped a whole role section to force 2 pages and Luke pushed back: "Overall, I think you've been too aggressive on cutting down the length and you've focused on the wrong places... look for sentences where only or two words run onto a new line and see if you can reword them so that whole line is saved."

**Line-wrap orphan analysis** (the right first move before chopping content):

1. Extract per-line text from the rendered PDF with pdfminer's `extract_pages` + `LTTextLine`.
2. Find lines containing 1-3 words that aren't bullet markers, dates, or section headings.  Each such line is an "orphan" — a paragraph or bullet whose last few words wrapped to their own line, costing a full line of vertical space for two or three words of content.
3. For each orphan, rewrite the source sentence to shave 2-5 words from elsewhere in the same sentence.  That often pulls the orphan back onto the previous line, saving a full line of vertical space.
4. Typical wording moves: combine two short sentences with a semicolon; replace "led to better-aligned X" with "improved X"; drop articles ("a", "the"); compress parentheticals; merge prepositional phrases.

This works much better than dropping content.  A surgical session can shave 3-5 lines from a CV without losing any signal — often enough to fit Education back onto page 2, or to push a stuck bullet down to the previous page.

**The page-count progression**: section-deletion is the heaviest tool; bullet-trimming is the middle tool; line-wrap-orphan rewording is the surgical tool.  **Try surgical first.**  Section-deletion is the last resort, and per [[cv-variant-content-rule]] it must not create chronological gaps (compress in place rather than delete).

**The Word/Pages margin (BINDING — was previously a soft advisory).** The headless LibreOffice round-trip under-counts other word-processors by up to a page. Same `.docx`: 3 in headless but **4 in Apple Pages** (2026-05-23, Publications spilled) and again **4 in Microsoft Word** (2026-06-01, a payments-SaaS Head of Security variant — a content-heavy page 3). Because it has now recurred, headless-3 is **no longer an auto-pass** (see step 6): treat it as "likely 4 in the recipient's viewer" unless page 3 is demonstrably sparse. Variants with content well-distributed across page 3 are the high-risk ones; a sparse page 3 is low-risk. If Luke flags a post-ship discrepancy, the first cut to consider is the Publications section (lowest content-relevance — it tends to be what spills).

**Related**: [[cv-skills-section]], [[cv-variant-content-rule]], [[cv-rebuild]].
