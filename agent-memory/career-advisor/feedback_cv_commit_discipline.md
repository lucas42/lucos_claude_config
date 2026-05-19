---
name: cv-commit-discipline
description: Commit discipline for the CV repo (lucas42/lukeblaney_cv) — small targeted commits, source-only
metadata:
  type: feedback
---

When editing files in `lucas42/lukeblaney_cv`:

1. **Keep commits small and targeted.** One conceptual change per commit. A six-fix patch should be six commits, not one. The user explicitly asked for this on 2026-05-19.

2. **Only commit source, documentation, and build config.** Generated artefacts (`.pdf`, `.docx`, LaTeX intermediates `.aux`/`.log`/`.out`) must be excluded via `.gitignore` and never staged.

**Why:** The CV lives in source control and Luke wants a clean, readable history he can review change-by-change. Bundled "fix everything" commits make it hard to undo individual decisions.

**How to apply:** Stage and commit each logical fix separately, with a focused message. Before any commit, double-check the staged files list — if you see a `.pdf`/`.docx` in `git status`, fix `.gitignore` first and back out the artefact.

Related: [[cv-copy-editing-scope]], [[cv-dialect-preference]].
