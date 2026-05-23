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
- **Render script**: `render-tailored.sh` runs pandoc in Docker against the reference templates, producing `Luke Blaney - CV.docx` (committed, ATS-ready filename) by default. Pass `--pdf` to also produce `Luke Blaney - CV.pdf` (gitignored, for human review) — only needed when a specific application or recipient asks for a PDF (changed from "both by default" to "docx-only by default" on 2026-05-22; Luke doesn't open the PDFs and they're not committed, so generating them by default was just wasted render time).
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

## First-time deployments (2026-05-23)

A senior IC Software Security Engineer variant produced via `/tailor` for an AI-platform vendor (Acme AI Lab in worked-example terms) surfaced three pipeline fixes that are now part of the standard rendering path:

1. **Bullet-indent post-pandoc rewrite** (see `render-tailored.sh` comments) — pandoc generates its own `numbering.xml` entries with `left=720 hanging=480` (~0.5 inch text indent) regardless of what's in the reference template, because the template body has no bullet content for pandoc to inherit from. Result: bullets render with a deep indent that looks disproportionate in 2-bullet sections (Talks & Panels, Education, short role entries). Fix: post-pandoc Python step in `render-tailored.sh` rewrites every bullet `<w:ind>` to `left=360 hanging=360` (bullet character at the page margin, text at 1/4 inch). Tightest sensible setting for CV-style short bullets. Affects every future variant.
2. **EmployerDate `keepNext` + `keepLines`** (see `pandoc-docx-reference.docx.template` styles.xml) — the date-subtitle paragraph style under each role heading was missing `keepNext`, so the chain Heading → Date → Intro was sticky only on the Heading → Date link. Word's pagination spec allowed splitting heading + date at the bottom of one page from the intro paragraph at the top of the next. (LibreOffice headless was already keeping the chunk together visually but the spec allowed the split, so Word desktop occasionally orphaned the date subtitle from the intro paragraph.) Fix: added `<w:keepNext/>` and `<w:keepLines/>` to the `EmployerDate` style in the reference template. Heading + date + intro now move as a single chunk across page breaks.
3. **Form-probe-driven artefact-set** (see `/tailor` Step 3.5 and [[feedback-cover-letter-upload-field]]) — `/tailor` now probes the application form structure (Greenhouse `?questions=true`, Lever posting JSON, Ashby `applicationFormDefinition`) before deciding whether to render a `.docx` cover letter or write plain-markdown answers for individual textareas. First case in production: a Greenhouse form with no cover-letter file upload, just a required "Why {Company}?" textarea + optional "Additional Information" textarea — split letter content disjointly across the two answers. The skill's old Step 1 ("CV or CV+letter?") was removed in favour of deferring the artefact-set decision until after the form probe.

## First-time deployments (2026-05-23, second submission)

A developer-platform Staff IC variant produced via `/tailor` deployed three patterns for the first time:

1. **Jibe-on-iCIMS form-probe failure** (see [[ashby-job-board-api]]) — first case where the form-probe couldn't be completed externally (iCIMS application flow is session-bound, only the JD is publicly fetchable via the ld+json structured data embedded in the Jibe Apply page). The "CV-only-now-reconvene-with-`/tailor-cover-letter`-later" path was taken. Post-submission Luke confirmed the post-CV-profile questions were short-form only — no `/tailor-cover-letter` follow-up was needed. The pattern is captured for future Jibe / iCIMS applications.
2. **Cyber-as-platform-enablement framing — second deployment** (see [[user-role-framing]]) — first deployed on a different platform-engineering variant 2026-05-22; redeployed cleanly here. Pattern is stabilising: the reframe holds well when JD signals BCDR / compliance / security upgrades alongside platform-engineering.
3. **Agentic-coding-guardrails bridge to a developer-platform employer** — the lucos_agent / multi-persona-LLM-fleet Career Break framing was sharpened to bridge a developer-platform employer's "agentic software development" strategic framing. The "scoped per-app GitHub credentials and audit-trailed commits going through pull-request review" line read as on-brand for the audience. Pattern available for any future developer-platform / developer-tooling employer where agentic-coding is part of the company strategy.

Also surfaced 2026-05-23:

- **Headless LibreOffice vs Apple Pages page-count discrepancy** (see [[cv-page-count]]) — same `.docx` was 3 pages in headless LibreOffice but 4 in Apple Pages 15.2.1. Rule unchanged (≤ 3 in headless = ship without asking) but advisory added: variants where headless shows content well-distributed across page 3 are at risk of off-by-one spill in Pages / Word; Publications is the typical spill candidate.
