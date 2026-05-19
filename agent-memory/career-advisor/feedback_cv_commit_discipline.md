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

3. **Only commit source, documentation, and build config.** Generated artefacts (`.pdf`, `.docx`, LaTeX intermediates `.aux`/`.log`/`.out`) must be excluded via `.gitignore` and never staged.

**Why:** The CV lives in source control and Luke wants a clean, readable history he can review change-by-change for the durable / reusable stuff. But per-application variant creation is a single conceptual unit — splitting it adds noise without informational value, and each variant's history isn't going to be reviewed bullet-by-bullet anyway.

**How to apply:** When `/tailor-cv` (or equivalent variant creation work) starts, do all the variant-specific work locally before committing. Stage the new `cv-{role}.md`, the Dockerfile additions, and the `.circleci/config.yml` additions together. Commit once with a generic message — no employer names (see [[cv-application-privacy]]).

Source-of-truth additions surfaced during a variant consultation (e.g. a new bullet on `cv-extended.md`) are still their own commit, before the variant commit, since they're reusable.

Related: [[cv-copy-editing-scope]], [[cv-dialect-preference]], [[cv-application-privacy]].
