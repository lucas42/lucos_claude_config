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
- **Four tailored variants exist** in `lukeblaney_cv_tailored` across senior IC, Staff IC, and management-track roles in domains including SME lending, partner-marketing, hospitality, and retail investing. All 3 pages, ATS metrics clean. The most recent variant (a retail-investing fintech Staff IC role, 2026-05-21) was the first to deploy the Architect→PE absorption framing (continuous-architecture-2016-to-2025 in Summary; explicit absorption bullet in the collapsed PE entry) and the first under Luke's whitespace conventions (auto-preserved double-spacing via render-script pre-processor).
- **`render-tailored.sh` pre-processor** (added 2026-05-21): auto-converts ASCII `.  ` (period + 2 spaces) to `. \xa0` (period + space + U+00A0 nbsp) before pandoc runs, so Luke's typewriter-style double-spacing convention survives end-to-end into the rendered docx/pdf. Source files stay clean and readable.

Outstanding work that would still be useful:
- Pull-forward exceptions for individual entries from the dropped sections (Earlier Career pre-Assanka, Positions of Responsibility) — currently handled per-application in [[cv-variant-content-rule]].
- Worked example for Director-track variants other than the platform-engineering / IC variants already produced.

## First-time deployments (2026-05-22)

A Staff Platform Engineer variant produced via `/tailor` deployed four new conventions for the first time:

1. **Cyber-as-platform-enablement framing** (see [[user-role-framing]]) — reframed the cyber years as a platform / enablement function with engineering teams as customers, rather than as traditional cyber-security leadership. Honest because the FT cyber team genuinely operated that way (democratisation of security data, advice across engineering teams, SSO paved path). Applicable to any platform-engineering JD where cyber is part of Luke's recent surface but not the primary draw.
2. **Sharpened scope on the Architect-titles-phased-out framing** (see [[user-role-framing]], [[check-evidence-recency]]) — the "Architect role phased out, architecture absorbed into PE remit" narrative is now scoped to Architect-titled JDs only. For non-Architect senior IC variants it reads as "Luke was forced out of architecture by the org reshuffle" and explains a concept (engineers making architectural decisions) the target org already operates by. Default for non-Architect senior IC variants: state architectural continuity plainly as part of the PE remit.
3. **`.docx`-as-truth verification** (see [[cv-page-count]]) — `/tailor` and `/tailor-cv` now round-trip the rendered `.docx` to PDF via LibreOffice in docker (`linuxserver/libreoffice` image) before counting pages. The previously-trusted LaTeX-PDF page count is no longer authoritative because the `.docx` and LaTeX-PDF use different layout engines and can disagree by a page or more.
4. **Skills section: 5-category, single-paragraph layout** (see [[cv-skills-section]]) — categories collapsed from ~8 to ~5; layout uses pandoc hard-line-breaks (`\` line-continuation) to produce one paragraph rather than N paragraphs. Removes the inter-paragraph spacing in the `.docx` that was taking roughly a third of a page in older 8-category variants.
