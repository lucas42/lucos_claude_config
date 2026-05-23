---
name: feedback-cover-letter-upload-field
description: Don't assume the cover-letter format from the JD URL — probe the application form first. Defaults span file-upload (.docx), single textarea, and per-question textareas with disjoint-content requirements.
metadata:
  type: feedback
---

**Probe the application form before deciding the cover-letter format.** ATS application forms vary widely in how they accept letter-shaped content:

- **File upload** (e.g. Greenhouse `input_file` labelled "Cover Letter"): submit a `.docx`.
- **Single cover-letter textarea** (e.g. Lever roles with a `textarea` cover-letter field, no file alternative): submit the letter body as plain text.
- **Per-question textareas with no cover-letter field at all** (e.g. an LLM-platform vendor's Greenhouse form with a required "Why {Company}?" textarea + optional "Additional Information" textarea, no cover-letter file or textarea per se — observed 2026-05-23 on a real application): split the would-be-letter content across the answers with disjoint coverage.
- **Combination** (e.g. cover-letter file upload + custom "Why X?" textarea): produce both, with cleanly disjoint content split between them.

**Why:** Stated 2026-05-23. Initial version of this rule (2026-05-21) said file-upload was the default and Luke had to flag textareas. That was wrong twice over: (a) it assumed which format the form uses without checking; (b) it didn't cover the per-question textarea case at all, leading to a wasted `.docx` cover letter for a Greenhouse form whose actual fields were a required "Why {Company}?" textarea + optional "Additional Information" textarea (no cover-letter file at all). The correct default is "probe first, decide format from what the form actually accepts" — not "guess file-upload and adjust later".

**How to apply:**
- `/tailor` Step 3.5 (and equivalent step in `/tailor-cover-letter`) probes the application form via the same ATS API endpoint used for the JD content. For Greenhouse: `?questions=true`. For Lever: posting JSON includes form metadata. For Ashby: `applicationFormDefinition` in posting-api. For Workday / iCIMS / Taleo: ask Luke to paste / describe.
- Categorise each content-bearing field as CV-file / cover-letter-file / cover-letter-textarea / per-question-textarea / additional-information / non-content.
- Render to `.docx` ONLY when the field is a file-upload. For textarea fields the markdown source IS the submission artefact (Luke copy-pastes); don't render an unused `.docx`.
- When multiple textareas exist, plan a disjoint content split BEFORE drafting. Re-verify in self-checks that the same facts/framings don't appear in two answers.
- Markdown remains the source of truth and what gets committed for content review, regardless of submission format.
- For applications where the form has no cover-letter-shaped field AND no content-bearing custom questions, stop and ask Luke before drafting anything letter-shaped — there may be no place to put it.

Related: [[project-cover-letter-rebuild]], [[cv-rebuild]].
