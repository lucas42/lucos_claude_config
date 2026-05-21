---
name: cv-rebuild
description: CV pipeline rebuild — largely complete as of 2026-05-21. Pandoc + markdown source-of-truth pipeline is live; `/tailor` and `/tailor-cv` skills operate against it.
metadata:
  type: project
---

Rebuild of `lucas42/lukeblaney_cv` to fix ATS-parseability problems. Started 2026-05-19. **Largely complete as of 2026-05-21** — pipeline is live and three tailored variants have been produced through it.

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

## Current state (2026-05-21)

The pipeline is operational. Key infrastructure in place:

- **Source-of-truth**: `cv-extended.md` (full history, ATS-clean, no em-dashes).
- **General-purpose CV**: `cv.md` (curated subset of cv-extended.md).
- **Tailored variants**: produced under `lukeblaney_cv_tailored/orgs/{company}/{role}/cv.md` via the `/tailor` or `/tailor-cv` skills.
- **Render script**: `render-tailored.sh` runs pandoc in Docker against the reference templates, producing `Luke Blaney - CV.docx` (committed, ATS-ready filename) and `Luke Blaney - CV.pdf` (gitignored, for human review).
- **Templates**: `pandoc-docx-reference.docx.template` (uses Calibri theme, exact line-height for renderer parity, `EmployerDate` custom paragraph style for italicised date subtitles) and `pandoc-pdf-header.tex.template` (matching LaTeX). The Lua filter `employerdate-filter.lua` translates `EmployerDate` divs to a LaTeX environment for PDF renders.
- **ATS verification**: `/tmp/pdfvenv/bin/python3` with `pdfminer.six` verifies the rendered PDF — page count, cid/ligature/hyphen artefact count, JD keyword presence. Bootstrap line in `/tailor` and `/tailor-cv` skills handles the venv if missing.
- **Four tailored variants exist** in `lukeblaney_cv_tailored`: funding-circle / partnerize / airbnb / freetrade. All 3 pages, ATS metrics clean. Freetrade (2026-05-21) was the first variant to deploy the Architect→PE absorption framing (continuous-architecture-2016-to-2025 in Summary; explicit absorption bullet in the collapsed PE entry) and the first under Luke's whitespace conventions (auto-preserved double-spacing via render-script pre-processor).
- **`render-tailored.sh` pre-processor** (added 2026-05-21): auto-converts ASCII `.  ` (period + 2 spaces) to `. \xa0` (period + space + U+00A0 nbsp) before pandoc runs, so Luke's typewriter-style double-spacing convention survives end-to-end into the rendered docx/pdf. Source files stay clean and readable.

Outstanding work that would still be useful:
- Pull-forward exceptions for individual entries from the dropped sections (Earlier Career pre-Assanka, Positions of Responsibility) — currently handled per-application in [[cv-variant-content-rule]].
- Worked example for Director-track variants other than the platform-engineering / IC variants already produced.
