---
name: cover-letter-rebuild
description: Active project — build a reusable cover-letter library and tailoring workflow in the lukeblaney_cv repo
metadata:
  type: project
---

Active rebuild of Luke's cover-letter workflow. Started 2026-05-20.

**Why:** Luke's existing letters share heavy boilerplate, miss "why this company" content, and don't surface his strongest evidence (which sits locked in a civil-service personal statement). Diagnostic patterns captured in [[user-cover-letter-patterns]].

**Three-step plan** (Luke chose all three on 2026-05-20, in this order):

1. **Library** — reusable building blocks committed to `lucas42/lukeblaney_cv/cover-letters/`: openers, evidence stories (mined from civil-service statement), career-break framings, closes, and a "why this company" prompt-checklist. No employer names — keeps repo public-safe per [[cv-application-privacy]].
2. **Worked example** — rebuild one of the existing weak letters end-to-end using the new structure, to prove the approach before automating.
3. **/tailor-cover-letter skill** — mirror the existing `/tailor-cv` skill: feed it a JD URL, it pulls library blocks, asks JD-specific questions, drafts a tailored letter for sign-off.

**Structural template chosen** (4 short paragraphs, ~250–350 words total):
1. Anchor — specific role + sharp claim (no "I'm an X who…" opener)
2. Evidence — one or two concrete stories with outcomes
3. Why this company — something real about them
4. Forward-looking close — current focus + invitation to talk

**How to apply:** Follow [[cv-commit-discipline]], [[cv-copy-editing-scope]], [[cv-dialect-preference]], [[cv-application-privacy]] when working in the cover-letters/ directory. Individual letter drafts for live applications are NOT committed (privacy); only the reusable building-block library and templates.

## Company-notes convention (for the private tailored repo)

When working on a live application, persist per-employer context in `lukeblaney_cv_tailored/company-notes/{slug}.md`. The `/tailor-cover-letter` skill (step 3) should read this file before drafting.

**One file per company, not per (company, role) pair.** Luke may apply to multiple roles at the same company over time — the company-level context (hiring manager, recruiter style, ATS in use, application history, anything the company itself has told him) is cross-cutting and shouldn't be duplicated. Inside each company file, use role-specific sub-sections for things that don't generalise:

```markdown
# {Company}

## Company-level notes
- ATS: Greenhouse
- Hiring manager (Eng): {name}
- {anything cross-cutting}

## Roles applied for

### {Role title} — {date applied}
- JD link / archive
- Letter draft path
- Recruiter / feedback
- Outcome

### {Other role} — {date applied}
- …
```

Slugs should be lowercase-kebab of the company name (`bbc.md`, `tfl.md`, `funding-circle.md`).

Related: [[cv-rebuild]], [[user-cover-letter-patterns]].
