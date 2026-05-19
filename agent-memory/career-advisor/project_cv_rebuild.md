---
name: cv-rebuild
description: Active project — rebuild Luke's CV pipeline around pandoc + markdown source-of-truth
metadata:
  type: project
---

Active rebuild of `lucas42/lukeblaney_cv` to fix ATS-parseability problems. Started 2026-05-19.

**Diagnosis (confirmed via pdftotext extraction of `cv.pdf`)**: pdflatex with default Computer Modern renders bullets as `(cid:136)` glyphs (50+ in the file, breaking all structure for ATS parsers) and ligatures `ﬁ`/`ﬂ`/`ﬀ` as unmapped glyphs (breaking keyword matching for words like "Defined" / "workflow" / "different"). Footer URL also pollutes the text flow.

**Chosen direction**:
- Single source-of-truth: `cv-extended.md` (markdown) — contains everything; never submitted directly.
- Role variants are curated *subsets* of the extended doc, emphasising the most relevant bits per JD.
- Build via pandoc → both `.docx` (for ATS submissions) and `.pdf` (for human-to-human sending).
- Variant generation mechanism: not yet decided (likely start with copy-and-prune, automate only if needed).

**Six fixes outstanding for cv-extended.md** (suggested 2026-05-19, Luke green-lit on the same day):
1. Mid-word line-break hyphens (via pandoc/LaTeX option, build-config level)
2. Sparse contact block (need Luke to provide phone, city, LinkedIn, GitHub)
3. Spelling errors (`stragety`, `Succesfully`)
4. No `# Skills` section (per-variant, not source-of-truth)
5. Non-standard section names (e.g. "Talks & Panels", "Previous Work Experience", "Positions of responsibility")
6. Inline `[Note: Officially…]` line under Labs Developer (copy decision — needs consultation)

**Why this matters:** Luke is actively job hunting and ATS rejections are blocking him from reaching humans (3-minute auto-rejections, auto-fill putting fields in wrong slots). Fixing the pipeline is the highest-leverage move he can make right now.

**How to apply:** When working in this repo, follow [[cv-commit-discipline]], [[cv-copy-editing-scope]], [[cv-dialect-preference]]. Validate each fix by running pandoc → pdfminer extraction and counting cid/ligature/hyphen artefacts.
