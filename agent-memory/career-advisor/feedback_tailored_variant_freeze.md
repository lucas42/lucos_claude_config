---
name: tailored-variant-freeze
description: Sweep-scope rule for sweeping content / punctuation / formatting changes. Apply to all of lukeblaney_cv; apply to lukeblaney_cv_tailored only for actively-worked items. Historical / submitted variants stay frozen.
metadata:
  type: feedback
---

When making sweeping content, punctuation, or formatting changes (anything broader than fixing a single document for a specific application), the scope rule is:

- **`lukeblaney_cv` (source-of-truth + library)**: apply the change to everything. The source-of-truth and library are forward-facing; future variants and renders should inherit the latest standards.
- **`lukeblaney_cv_tailored` (per-application variants)**: apply the change only to items actively being worked on right now. Anything historic, anything where the application has already been submitted, leave as-is.

**Default to excluding historic / submitted tailored variants. Do NOT ask for confirmation; just don't touch them.** If Luke wants a historic variant re-rendered or rewritten, he'll ask explicitly.

**Why** (Luke stated 2026-05-21 after the em-dash sweep, where I re-rendered Partnerize / Funding Circle CVs / letters along with the Airbnb work):

1. **Maintenance burden scales with the tailored corpus.** Three variants is no big deal; thirty would be. Default-include grows linearly with applications, default-exclude stays constant.
2. **Submitted variants are a historical record.** They represent what a specific recruiter saw on a specific date. Retroactively re-rendering them produces an idealised "wish-I'd-done-this" version that no longer matches the actual submission. The git history at the commit before the sweep is the source-of-truth for "what was sent"; re-rendering overwrites that with a rewrite. For audit / interview prep / "what did they read" purposes, the actual submitted version is the one that matters.

**How to apply**:

- Sweeping changes to library blocks, `cv-extended.md`, `cv.md`, `pandoc-docx-reference.docx.template`, `pandoc-pdf-header.tex.template`, `render-tailored.sh`, voice memories: all of `lukeblaney_cv` and `~/.claude` is in scope. Sweep freely.
- Tailored variants in `lukeblaney_cv_tailored/orgs/{company}/{role}/`: only touch if Luke is actively drafting or rewriting that specific application. Otherwise leave the `.md` and `.docx` exactly as they sit in git.
- Template / font / spacing changes in `lukeblaney_cv` will affect FUTURE renders of tailored variants. But don't re-render the existing tailored `.docx` files to pick those up unless Luke explicitly asks.
- Exception: if Luke explicitly says "and please re-render everything" or "apply to all variants too", do it. The default is exclude.

Related: [[cv-commit-discipline]], [[cv-application-privacy]], [[cv-variant-content-rule]].
