---
name: cv-commit-discipline
description: Commit discipline for the CV repo (lucas42/lukeblaney_cv) — small targeted commits, source-only
metadata:
  type: feedback
---

When editing files in `lucas42/lukeblaney_cv`:

1. **Small commits for reusable / source-of-truth work.** One conceptual change per commit when editing `cv-extended.md`, the pandoc templates, the reference doc, the Dockerfile, CI config, or anything else that's reused across many variants. A six-fix patch should be six commits, not one. Stated 2026-05-19.

2. **One commit per new tailored variant.** When creating a new role-tailored CV (`cv-{role}.md`), bundle into a single commit: the new file, all the standard cuts (PE collapse, Earlier-Career compression, talks trim, etc.), and the Dockerfile / CircleCI build wiring. Don't fragment a variant's creation across many small commits — it's one piece of work that ships together. Stated 2026-05-20.

   Subsequent tweaks to an existing variant (proofreading edits, small content swaps) follow the small-commit rule again.

3. **Artefact-commit policy differs by repo:**
   - **Public `lukeblaney_cv`**: all rendered artefacts (`cv*.pdf`, `cv*.docx`, `.aux`/`.log`/`.out`) gitignored and never staged. The markdown source + pandoc templates regenerate them deterministically; committing them adds binary noise to a public history.
   - **Private `lukeblaney_cv_tailored`**: rendered submission artefacts ARE committed alongside their markdown source as the durable record of what was actually sent — both `Luke Blaney - CV.docx` (always) and `Luke Blaney - CV.pdf` (when produced via `render-tailored.sh --pdf` for direct share with a recruiter or for an application that asked for PDF). PDFs are only generated when the flag is passed deliberately, so any PDF in the tree is a real submission artefact, not incidental noise. Same logic for `Luke Blaney - Cover Letter.docx` / `.pdf`. The verification-only LibreOffice round-trip PDF (`*(from docx).pdf`) is gitignored via a specific pattern, as are LaTeX intermediates.

   Tightened 2026-05-27 after the LogicMonitor submission, where the gitignore was excluding `*.pdf` blanket and Luke flagged that any deliberate `--pdf` output should be commit-worthy.

**Why:** The CV lives in source control and Luke wants a clean, readable history he can review change-by-change for the durable / reusable stuff. But per-application variant creation is a single conceptual unit — splitting it adds noise without informational value, and each variant's history isn't going to be reviewed bullet-by-bullet anyway.

**How to apply:** When `/tailor-cv` (or equivalent variant creation work) starts, do all the variant-specific work locally before committing. Stage the new `cv-{role}.md`, the Dockerfile additions, and the `.circleci/config.yml` additions together. Commit once with a generic message — no employer names (see [[cv-application-privacy]]).

Source-of-truth additions surfaced during a variant consultation (e.g. a new bullet on `cv-extended.md`) are still their own commit, before the variant commit, since they're reusable.

Related: [[cv-copy-editing-scope]], [[cv-dialect-preference]], [[cv-application-privacy]].
