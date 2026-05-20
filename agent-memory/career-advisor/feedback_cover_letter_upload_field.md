---
name: feedback-cover-letter-upload-field
description: Most ATS systems take cover letters as a file upload (.docx / .pdf), not a paste-into-textbox field. The render pipeline is a first-class part of the cover-letter workflow, not an edge case.
metadata:
  type: feedback
---

ATS application forms more often than not present cover letters as a **file upload** field rather than a text-area paste-in. Treat .docx render as the default submission format for cover letters, not as an exotic edge case.

**Why:** I'd initially scoped the cover-letter render pipeline as a "rare exception" thing, with markdown-only as the default. Luke flagged (2026-05-21) that the upload-field shape is in fact common — he's seen it on many ATS pages.

**How to apply:**
- `/tailor-cover-letter` should produce a .docx alongside the markdown by default, not as an opt-in extra step.
- Treat the .docx as the submission artefact (same status as for tailored CVs).
- Markdown remains the source of truth and what gets committed for content review.
- .pdf is for human review (e.g. emailing a hiring manager directly).
- For applications that DO take a text-area (minority case), the markdown source is still pastable as-is.

Related: [[project-cover-letter-rebuild]], [[cv-rebuild]].
