---
name: textarea-url-scheme
description: Include the scheme (https://) on any URL written into a plain-text textarea submission. Bare-host URLs only work where the rendered link can differ from the displayed text.
metadata:
  type: feedback
---

When writing a URL into a plain-text submission artefact (textarea answer, application-form free-text field, anything copy-pasted directly into a form), **include the scheme** (`https://example.com/path`, not `example.com/path`).

**Why:** Stated 2026-05-23. In a textarea there's no distinction between display text and underlying link — what Luke pastes is what the reader sees and (if the form / downstream system auto-links URLs) what gets parsed. Bare-host URLs are unreliable: some auto-linkers detect them, many don't. Including the scheme is the only way to guarantee the URL is a working hyperlink regardless of the parser.

In **rendered formats** (`.docx`, `.pdf`, markdown rendered to HTML) the display text and underlying URL can differ — markdown `<https://example.com>` and the pandoc auto-link both produce a clickable link with the bare host displayed. So `.docx` cover letters, the CV's Career Break section, and similar rendered surfaces can keep bare-host displays without the scheme. **The rule applies only where the source IS the submission.**

**How to apply:**

- Variant A cover letter rendered to `.docx`: bare-host URLs are fine (the renderer auto-links).
- Variant A cover letter for a single textarea field: include `https://` on every URL.
- Variant B per-question textarea answer: include `https://` on every URL.
- CV (rendered to .docx): bare-host fine.
- Email body Luke pastes directly: include `https://`.
- LinkedIn About / public bio: include `https://`.

**Self-check**: in the textarea self-checks of `/tailor` Step 11 (Variant B section), grep each answer's source for URLs (`https?://\S+|\b[a-z0-9.-]+\.(com|co\.uk|io|net|org)/\S*`); for every match that doesn't start with `https://`, flag for the scheme to be added before submission.

Related: [[luke-voice]], [[feedback-cover-letter-upload-field]].
