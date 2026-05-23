---
name: cover-letter-rebuild
description: Cover-letter library + tailoring workflow — largely complete as of 2026-05-21. Library, skills, and worked examples are live.
metadata:
  type: project
---

Rebuild of Luke's cover-letter workflow. Started 2026-05-20. **Largely complete as of 2026-05-21**.

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

When working on a live application, persist per-employer context in `lukeblaney_cv_tailored/orgs/{company-slug}/notes.md`. The `/tailor` and `/tailor-cover-letter` skills read this file before drafting.

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
- Tailored CV path
- Letter draft path
- Recruiter / feedback
- Outcome
```

Slugs are lowercase-kebab of the company name. The role's CV / letter / .docx artefacts live in a `{role-slug}/` subdirectory under the company directory.

## Current state (2026-05-21)

The cover-letter system is operational. Key infrastructure in place:

- **Library** at `lucas42/lukeblaney_cv/cover-letters/`:
  - `template.md` — 4-paragraph structural template + rules.
  - `blocks/openers.md` — opener anchor patterns by role archetype (cyber leadership / platform leadership / Director-Head-VP of Engineering / IC-track / EM-TLM / company-is-the-hook).
  - `blocks/evidence-stories.md` — 9 stories mined from Luke's civil-service personal statement; situation → action → result for each, plus a story-selection cheat sheet keyed by JD signal.
  - `blocks/current-focus.md` — 4 variants: security-flavoured / platform-engineering-flavoured / IC-architect-flavoured / generalist-leadership-flavoured.
  - `blocks/career-break-aside.md` — one-line default + sentence-form for travel-relevant JDs.
  - `blocks/closes.md` — closing-line + sign-off options.
  - All library prose is em-dash-clean (~zero per [[luke-voice]]).
- **Skills**:
  - `/tailor-cover-letter` — letter-only flow.
  - `/tailor` — combined CV + cover letter flow with joint positioning decisions, cross-pollination between the two documents, and a single bundled commit.
- **Four worked-example applications** in `lukeblaney_cv_tailored/orgs/` across senior IC, Staff IC, and management-track roles in domains including SME lending, partner-marketing, hospitality, and retail investing. The hospitality-marketplace Staff IC variant was the first `/tailor` invocation; surfaced the IC-architect current-focus variant, the EmployerDate paragraph style, and the em-dash voice rule. The retail-investing-fintech Staff IC variant (2026-05-21) was the first deployment of the Architect→PE absorption bridge (see [[user-role-framing]]) and the first variant with Luke's whitespace conventions applied end-to-end (double-spaces auto-preserved by the render-script pre-processor; first-line indent written manually as a 16-char U+00A0 run). Also surfaced the "don't overclaim FT regulatory experience" rule and the "avoid JD acronym" voice rule.
- **AI-platform-vendor Senior SWSE variant** (2026-05-23, submitted) was the first `/tailor` invocation to encounter and prove out the form-probe-driven flow: a Greenhouse application with no cover-letter file upload, just a required "Why {Company}?" textarea (200-400 word target) + optional "Additional Information" textarea. The 4-paragraph cover letter was drafted first (default assumption) and then repurposed into two disjoint textarea answers — para 3 + most of 4 into "Why {Company}?", paras 1 + 2 + career-break aside into "Additional Information". The wasted `.docx` cover letter prompted the `/tailor` Step 3.5 refactor: probe the form before drafting, decide artefact format from what the form accepts. Also surfaced [[textarea-url-scheme]] (URLs in textareas need the `https://` scheme — bare-host display only works in rendered formats where display text and underlying link can differ), the "most directly relevant" voice rule (don't position one piece of evidence as more relevant than everything else Luke has done), the bullet-indent post-pandoc rewrite, the EmployerDate `keepNext` fix, and the privacy-scan-on-every-public-write strengthening of [[cv-application-privacy]] after I leaked the target employer's name into three memory files mid-session.

Backlog (would be useful but not blocking):
- More evidence stories: CMDB rewrites, MFA solution, Kubernetes migration, mobile-apps cloud migration. Backlog list captured at the bottom of `evidence-stories.md`.
- Gap-filling on existing stories: specific outcome numbers for stories #1, #2, #3, #4, #6, #7, #8, #9 (each story file has its `**Gaps**:` checklist).
- Worked example for the EM / TLM opener and the "company is the hook" opener.

Related: [[cv-rebuild]], [[user-cover-letter-patterns]], [[tailored-variant-freeze]].
