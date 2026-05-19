---
name: tailor-cv
description: Build a JD-tuned variant of Luke's CV from a job-description URL. Interactive throughout — asks for clarification on gaps and proposes drafts for sign-off before committing.
disable-model-invocation: false
---

Build a curated submission CV tuned to a specific job description, derived from the source-of-truth at `~/sandboxes/lukeblaney_cv/cv-extended.md`.

The JD URL is provided as the first argument (e.g. `/tailor-cv https://jobs.ashbyhq.com/...`). If no URL is provided, ask the user for one before proceeding.

## Step 0: Routing

This is career-advisor work — it uses the career-advisor GitHub identity for commits, follows career-advisor memory conventions, and writes career-advisor agent memories when new information surfaces.

- **If you are the career-advisor agent**: follow the steps below directly.
- **If you are any other agent**: send a message to the `career-advisor` teammate:
  > "tailor-cv {url}"
  
  Then wait for the career-advisor to report back. Do not perform the work yourself.

## Step 1: Load standing rules

Read these memory files before starting — they carry standing rules for editing Luke's CV:

- `~/.claude/agent-memory/career-advisor/feedback_cv_commit_discipline.md` — small targeted commits; source-only; gitignore artefacts
- `~/.claude/agent-memory/career-advisor/feedback_cv_copy_editing_scope.md` — mechanical edits OK; copy changes need consultation
- `~/.claude/agent-memory/career-advisor/feedback_cv_dialect_preference.md` — UK English, Northern Hiberno-English default, London-comprehensible, no Americanisms
- `~/.claude/agent-memory/career-advisor/feedback_cv_variant_content_rule.md` — default-drop Earlier Career & Positions of Responsibility from submission variants; pull individual entries forward only when directly relevant to the target employer/industry
- `~/.claude/agent-memory/career-advisor/project_cv_rebuild.md` — context for the CV pipeline rebuild

## Step 2: Fetch the JD

Identify the ATS from the URL pattern and fetch the full job description:

- **Ashby** (`jobs.ashbyhq.com/{org}/{uuid}`): `curl -s "https://api.ashbyhq.com/posting-api/job-board/{org}?includeCompensation=true"` returns all jobs; filter for the matching `id`. Each job has `descriptionPlain` and `descriptionHtml` fields.
- **Greenhouse** (`boards.greenhouse.io/{board}/jobs/{id}` or `job-boards.greenhouse.io/{board}/jobs/{id}`): `curl -s "https://boards-api.greenhouse.io/v1/boards/{board}/jobs/{id}"`.
- **Lever** (`jobs.lever.co/{company}/{id}`): `curl -s "https://api.lever.co/v0/postings/{company}/{id}"`.
- **Workday** / **iCIMS** / **Taleo** / generic: try WebFetch first. These often render content client-side — if WebFetch returns thin content, ask the user to paste the full JD text into the conversation.

Extract:

- Role title and seniority level
- Company name, team or department, location, employment type
- Full job description text (responsibilities + qualifications + nice-to-haves + benefits + culture blurb)
- Salary / compensation if disclosed

## Step 3: Analyse the JD

Present an analysis to Luke covering:

1. **Role level and shape** — IC, manager, hybrid; junior/mid/senior/staff/principal/director/head/VP. Cite the phrases that signal this.
2. **Top-weighted signals** — requirements mentioned multiple times or with strongest language. These are what the JD really cares about; the variant must emphasise them.
3. **Hard requirements** — must-have qualifications, years, technologies, certifications, languages, location/visa.
4. **Soft requirements** — nice-to-haves, cultural signals, methodology preferences.
5. **ATS-relevant keywords** — explicit programming languages, frameworks, methodologies, tools, domain terms. List these explicitly; they will be the basis for the Skills section.
6. **Inferred priorities** — what does the JD imply about the company's positioning, the team's challenges, or the hiring manager's pain?

Pause here for Luke to confirm the analysis lands before going further. Especially flag any unusual or buzz-heavy framing — Luke may have a view on how authentically to match it.

## Step 4: Match Luke's experience against the JD

Read the current `~/sandboxes/lukeblaney_cv/cv-extended.md`. Produce a strengths/gaps table for Luke:

- **Strong alignment** — for each top JD signal, cite the most relevant existing bullet(s) in cv-extended.md (paraphrase or quote).
- **Weak / missing** — for each hard or important requirement that has weak or no evidence, flag it as a gap.

Present this before going further.

## Step 5: Gap consultation

For each significant gap, ask Luke a focused question. Useful framings:

- **Missing skill or technology**: "The JD asks for {X}. Your CV doesn't mention it. Do you have honest experience that could be claimed, evidence outside the CV (GitHub, personal projects, prior unlisted work), or should we accept this as a gap?"
- **Level-positioning mismatch**: "You're applying for {level Y} but your most recent title is {level Z}. How do you want to frame this?"
- **Domain mismatch**: "The JD is in domain {D}. Your experience is mostly in {E}. Any directly-relevant work we should highlight?"
- **Language / tech keyword absent**: "The JD specifies {language}. What can you honestly defend in a technical interview? List languages with rough recency for each."
- **Career break framing**: if the recent career break is relevant, ask how Luke wants to position it for this audience.

Use `AskUserQuestion` for structured choices where there are clear options; use prose questions where the answer is open-ended (e.g. specific dates, project details).

**When Luke provides new information to fill a gap:**

1. Use it in the variant being built.
2. **Decide whether it should also be added to `cv-extended.md`** for future applications. If the information is a true and useful fact about Luke's career/skills/experience that wasn't previously recorded, propose adding it. New facts in `cv-extended.md` go in as their own commit *before* the variant work, so future invocations of this skill inherit them. Get Luke's sign-off on the wording before committing.
3. Consider whether the new information should also be recorded as a career-advisor memory (e.g. a project-context fact, a skill confirmation, or a feedback rule about how to position something).

## Step 6: Propose drafts

Per `feedback_cv_copy_editing_scope.md`, any new copy needs consultation. Show Luke draft text for:

1. **Summary line / paragraph** (2-4 sentences positioning him for this specific role, addressing any level-positioning concerns)
2. **Career Break / Current Focus** (if relevant — see his existing voice in cv-extended.md's "Career Break & Current Focus" section)
3. **Skills section** (grouped categories, comma-separated keywords, JD-tuned). Categories to consider: Technical Leadership, Programming & Systems, Engineering Practice, Cloud & Platform, Generative AI, Cyber Security. Reorder or substitute categories based on the JD's emphasis.
4. **Bullet reframes** (any existing bullets that should be reordered or rephrased — e.g. moving the unbackfilled-Principal-Engineer bullet to the front of the Director and Interim VP roles for an IC-track variant)

Get sign-off on each block before writing the variant file.

## Step 7: Create the variant file

Choose a filename matching the role archetype, not the specific employer: `cv-staff-engineer.md`, `cv-platform-architect.md`, `cv-security-engineering-manager.md`. (One file can serve many similar applications; we trim the role title in the file to be generic.)

Create `~/sandboxes/lukeblaney_cv/cv-{role}.md` as a copy of `cv-extended.md`, then apply (each as its own focused commit per `feedback_cv_commit_discipline.md`):

1. Add Summary section between contact block and Employment (use `# Summary` heading)
2. Add Career Break & Current Focus section (if applicable, before Skills)
3. Add Skills section with JD-tuned grouped keywords (use `# Skills` heading)
4. Apply role-specific bullet reframes per Step 6

## Step 8: Apply standard cuts to hit page target

Variants land at **3 pages** by default — Luke's historical pattern across cv.tex, cv-tech.tex, cv-architect.tex, cv-security.tex. 2 pages is possible with more aggressive cuts but only when the audience demands it.

Apply these standard cuts (each as its own commit):

1. **Collapse adjacent Principal Engineer entries** — cv-extended.md has three PE entries covering Feb 2018 - Mar 2022. For most variants, combine into a single entry titled `## Principal Engineer - Reliability Engineering, Cyber Security, Observability & Edge Delivery` with dates `Financial Times: February 2018 - March 2022`. Keep 5-7 best bullets across the three.
2. **Compress oldest roles to Earlier Career section** — roles 10+ years old become one-line entries in a `# Earlier Career` section. Currently this means Labs Developer (FT Labs, Dec 2011 - Dec 2014) and Web Developer (Assanka, Nov 2010 - Dec 2011). Format: `- Company - **Role**: dates`.
3. **Trim Talks & Panels to top 4 entries** — keep the most JD-relevant. Examples: for security/observability roles, keep LeadDev 2021, InfoQ 2020, QCon 2020, Varnish Summit 2016.
4. **Drop reflective closing paragraphs** in non-recent role entries — e.g. the "I think my proudest accomplishment..." paragraph under Architect - Content.
5. **Drop Education's A-levels and GCSEs** (`## A-levels and GCSEs` / Lagan College) — too old for any tech submission.
6. **Drop `# Earlier Career` (pre-Assanka entries: Sainsbury's etc.) and `# Positions of Responsibility`** — per `feedback_cv_variant_content_rule.md`. *Exception*: pull forward any individual entry directly relevant to the target employer or industry (Luke's worked example: his Sainsbury's Customer Services role pulled into a Sainsbury's application).

## Step 9: Wire into the build pipeline

Update `~/sandboxes/lukeblaney_cv/Dockerfile`. Find the existing pandoc build block and append parallel lines for the new variant:

```
RUN pandoc cv-{role}.md -H pandoc-pdf-header.tex.template -V fontsize=10pt -o cv-{role}.pdf
RUN pandoc cv-{role}.md --reference-doc=pandoc-docx-reference.docx.template -o cv-{role}.docx
```

The `pandoc-docx-reference.docx.template` file in the repo tightens DOCX margins/font/spacing to match the PDF density. Without it, the DOCX renders as ~2x more pages than the PDF.

Update `~/sandboxes/lukeblaney_cv/.circleci/config.yml` to add `store_artifacts` entries:

```yaml
      - store_artifacts:
          path: cv-{role}.pdf
      - store_artifacts:
          path: cv-{role}.docx
```

This is one commit.

## Step 10: Build and verify

From the repo root: `rm -f *.pdf *.docx *.aux *.log *.out && docker build --output . .`

Then run a Python verification:

```bash
/tmp/pdfvenv/bin/python3 <<'EOF'
from pdfminer.pdfparser import PDFParser
from pdfminer.pdfdocument import PDFDocument
from pdfminer.pdfpage import PDFPage
from pdfminer.high_level import extract_text
import re

path = '/home/lucas.linux/sandboxes/lukeblaney_cv/cv-{role}.pdf'
with open(path,'rb') as f:
    pages = list(PDFPage.create_pages(PDFDocument(PDFParser(f))))
text = extract_text(path)
print(f'Pages: {len(pages)}, words: {len(text.split())}')
print(f'cid={len(re.findall(r"(cid:\\d+)", text))}  '
      f'ligs={sum(text.count(c) for c in [chr(0xFB01),chr(0xFB02),chr(0xFB00)])}  '
      f'hyphens={len(re.findall(r"\\w-\\n\\w", text))}')

# Check JD keyword presence — substitute the actual top keywords from Step 3
jd_keywords = [...]
lower = text.lower()
missing = [k for k in jd_keywords if k not in lower]
print(f'JD keywords missing: {missing if missing else "none"}')
EOF
```

Targets:
- **Pages**: 3 (acceptable: 2). If 4+, propose further cuts below.
- **cid / ligs / hyphens**: all 0 (these are non-negotiable; if any are >0 the geometry/header is broken)
- **JD keywords**: all top-tier keywords present

If page count is over 3, propose further cuts to Luke before applying:
- Drop Talks & Panels entirely (~0.5 page)
- Combine Director + Interim VP into a single "Senior Cyber Security Leadership" entry
- Tighten Career Break paragraph to two sentences
- Trim less-differentiating bullets in recent roles

If page count is 2 unintentionally (too aggressive), it's usually fine — but check the rendered output reads with enough density of substance.

## Step 11: Push and report

```bash
cd ~/sandboxes/lukeblaney_cv && git push origin main
```

Report back to Luke with:

- **Filename** of the new variant (`cv-{role}.md`, `.pdf`, `.docx`)
- **Final page count and word count**
- **ATS metrics** (cid / ligs / hyphens all 0)
- **JD keyword check** (which top keywords confirmed present)
- **Number of commits applied**, with messages
- **Where to submit from**: the `.docx` is for ATS submissions; the `.pdf` is for human-to-human sending
- **Any new content added to cv-extended.md** during Step 5 — call this out so Luke knows the source-of-truth was updated

If the role is one Luke is genuinely applying for, recommend reading the rendered PDF and DOCX once before submission.

## Git identity

All commits use the career-advisor GitHub App. Use the standard wrappers:

```bash
~/sandboxes/lucos_agent/git-as-agent --app career-advisor commit -m "..."
~/sandboxes/lucos_agent/gh-as-agent --app career-advisor ...
```

Commit directly to `main` — there is no PR/review workflow on `lukeblaney_cv`. See `feedback_cv_commit_discipline.md` for full discipline (small commits, source-only, gitignore artefacts).

## When this skill is not the right tool

- **The user wants to update cv-extended.md without a JD context** — that's just a normal career-advisor edit; do it inline.
- **The user wants a cover letter** — out of scope for this skill. A separate `/cover-letter` skill could be built later.
- **The JD URL is for a role Luke is firmly not applying for and just wants analysis** — do Steps 1-4 only and stop; don't build a variant.
- **No `cv-extended.md` exists, or it has obvious structural problems** — fix cv-extended.md first as a separate piece of work.
