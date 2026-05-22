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

## Step 1: Load standing rules and pre-confirmed Luke-facts

Read these memory files before starting:

**Standing rules** (how to work on the CV):
- `~/.claude/agent-memory/career-advisor/feedback_cv_commit_discipline.md` — small targeted commits for reusable work; one bundled commit per new variant; source-only; gitignore artefacts
- `~/.claude/agent-memory/career-advisor/feedback_cv_copy_editing_scope.md` — mechanical edits OK; copy changes need consultation
- `~/.claude/agent-memory/career-advisor/feedback_cv_dialect_preference.md` — UK English, Northern Hiberno-English default, London-comprehensible, no Americanisms
- `~/.claude/agent-memory/career-advisor/feedback_cv_variant_content_rule.md` — default-drop Earlier Career & Positions of Responsibility from submission variants; pull individual entries forward only when directly relevant to the target employer/industry
- `~/.claude/agent-memory/career-advisor/feedback_cv_application_privacy.md` — no employer-applied-to names in commits, memory files, filenames, or anywhere else that lands in a public repo

**Pre-confirmed Luke-facts** (don't re-ask things settled here):
- `~/.claude/agent-memory/career-advisor/user_skills_inventory.md` — defensible languages, databases, methodologies; what Luke will and won't claim
- `~/.claude/agent-memory/career-advisor/user_role_framing.md` — level-positioning, manager-vs-IC tilts, career-break voice

**Project context**:
- `~/.claude/agent-memory/career-advisor/project_cv_rebuild.md` — CV pipeline rebuild context

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

**Before asking Luke anything, check the pre-confirmed facts loaded in Step 1:**

- For tech / language / database / methodology gaps: check `user_skills_inventory.md` first. If a JD asks for Python, Ruby, React, MySQL, Redis, TDD, DDD, etc., the inventory already says whether Luke claims it. Don't re-ask.
- For level-positioning or framing gaps: check `user_role_framing.md`. Director→IC, Director→Director, career-break voice — all settled framings live here.

Ask Luke only about gaps that aren't covered by those files.

For genuinely new gaps, ask a focused question. Useful framings:

- **Missing skill / technology not in inventory**: "The JD asks for {X}. Inventory doesn't cover it. Do you have honest experience that could be claimed, evidence outside the CV (GitHub, personal projects, prior unlisted work), or should we accept this as a gap?"
- **Level-positioning mismatch not in framing memory**: "You're applying for {level Y} but your most recent title is {level Z}. How do you want to frame this?"
- **Domain mismatch**: "The JD is in domain {D}. Your experience is mostly in {E}. Any directly-relevant work we should highlight?"
- **Anything not anticipated by the existing memories**: ask in prose if open-ended, `AskUserQuestion` if multi-choice.

**When Luke provides new information to fill a gap (default-save rules):**

1. **Use it in the variant being built.**
2. **Default-save to a user-type memory** unless trivially obvious or ephemeral:
   - Tech / language / framework / database / methodology defensibility → append to `user_skills_inventory.md`
   - Level-positioning / role-framing / voice preferences → append to `user_role_framing.md`
   - Tell Luke in a one-line summary what's being saved as a courtesy ("Saving to inventory: Python confirmed comfortable, React excluded"). Don't block on confirmation for clearly-stable facts — Luke has explicitly OK'd default-save behaviour.
3. **Also consider adding to `cv-extended.md`** for facts that should appear on the CV itself (e.g. Kafka exposure, a specific architectural achievement). New CV content goes in as its own commit *before* the variant work, so future invocations inherit it. Get Luke's sign-off on the exact wording before committing.

## Step 6: Propose drafts

Per `feedback_cv_copy_editing_scope.md`, any new copy needs consultation. Show Luke draft text for:

1. **Summary line / paragraph** (2-4 sentences positioning him for this specific role, addressing any level-positioning concerns)
2. **Career Break / Current Focus** (if relevant — see his existing voice in cv-extended.md's "Career Break & Current Focus" section)
3. **Skills section** — target **~5 categories** (not 8) of grouped, comma-separated keywords, JD-tuned. Categories to consider: Technical Leadership, Programming & Systems, Engineering Practice, Cloud & Platform, Generative AI, Cyber Security. Pick ~5 by consolidating adjacent themes for the specific JD; reorder so the most JD-relevant category leads. **Layout**: structure as a single paragraph with hard line breaks between categories (`\` at end of each line except the last), not as separate paragraphs — this avoids inter-paragraph spacing bloat. See [[cv-skills-section]] for the rule and the markdown template.
4. **Bullet reframes** (any existing bullets that should be reordered or rephrased — e.g. moving the unbackfilled-Principal-Engineer bullet to the front of the Director and Interim VP roles for an IC-track variant)

Get sign-off on each block before writing the variant file.

## Step 7: Create the variant file (do all the work locally before committing)

Per `feedback_cv_commit_discipline.md`, **variant creation is a single bundled commit** — don't split it across multiple commits the way source-of-truth edits are split. Do all the steps below locally first, then commit once at the end of Step 9.

Tailored CVs live in the **private** `lukeblaney_cv_tailored` repo alongside their matching cover letter and company notes — not in the public `lukeblaney_cv` repo. The path is:

```
~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md
```

- `{company-slug}` matches the existing folder for that employer (or a new lowercase-kebab one if first application — also create `notes.md` per `/tailor-cover-letter` Step 5).
- `{role-slug}` is a lowercase-kebab subdirectory inside the company folder, holding both the CV and the cover letter for this specific role (e.g. `staff-software-engineer-short-term-credit/`).
- The filename inside is always **`cv.md`** — the role context comes from the directory name, so the filename names only the document type. The matching cover letter sits next to it as `cover-letter.md`.

Because the destination is private, both directory and filename can describe the specific JD — no archetype-only privacy constraint applies (per `feedback_cv_application_privacy.md`, employer-naming is fine in the private repo).

Create the variant file as a copy of `~/sandboxes/lukeblaney_cv/cv-extended.md`, then apply (still locally, not yet committed):

1. Add Summary section between contact block and Employment (use `# Summary` heading)
2. Add Career Break & Current Focus section (if applicable, before Skills) — **wrap the date line (`March 2025 – present`) in `::: {custom-style="EmployerDate"} ... :::` so it picks up the italic, tight-spacing paragraph style. Existing Employment / Education subtitle lines in cv-extended.md are already wrapped; the Career Break section needs the wrapping applied during variant creation because cv-extended.md doesn't include that section.**
3. Add Skills section with JD-tuned grouped keywords (use `# Skills` heading)
4. Apply role-specific bullet reframes per Step 6

The `EmployerDate` paragraph style is defined in the docx reference template; a matching `employerdate` LaTeX environment + Lua filter handles the PDF render. Anywhere a date subtitle appears under a heading, wrap it in this custom-style div. Don't add markdown italic `*...*` separately — the style supplies the italic itself.

## Step 8: Apply standard cuts (still in the same uncommitted state)

Variants land at **3 pages** by default — Luke's historical pattern for submission CVs. 2 pages is possible with more aggressive cuts but only when the audience demands it. The new general-purpose `cv.md` in `lukeblaney_cv` is a worked example of these cuts applied.

Apply these standard cuts (all as part of the single variant commit at the end of Step 9):

1. **Collapse adjacent Principal Engineer entries** — cv-extended.md has three PE entries covering Feb 2018 - Mar 2022. For most variants, combine into a single entry titled `## Principal Engineer - Reliability Engineering, Cyber Security, Observability & Edge Delivery` with dates `Financial Times: February 2018 - March 2022`. Keep 5-7 best bullets across the three.
2. **Compress oldest roles to Earlier Career section** — roles 10+ years old become one-line entries in a `# Earlier Career` section. Currently this means Labs Developer (FT Labs, Dec 2011 - Dec 2014) and Web Developer (Assanka, Nov 2010 - Dec 2011). Format: `- Company - **Role**: dates`.
3. **Trim Talks & Panels to top 4 entries** — keep the most JD-relevant. Examples: for security/observability roles, keep LeadDev 2021, InfoQ 2020, QCon 2020, Varnish Summit 2016.
4. **Drop reflective closing paragraphs** in non-recent role entries — e.g. the "I think my proudest accomplishment..." paragraph under Architect - Content.
5. **Drop Education's A-levels and GCSEs** (`## A-levels and GCSEs` / Lagan College) — too old for any tech submission.
6. **Drop `# Earlier Career` (pre-Assanka entries: Sainsbury's etc.) and `# Positions of Responsibility`** — per `feedback_cv_variant_content_rule.md`. *Exception*: pull forward any individual entry directly relevant to the target employer or industry (Luke's worked example: his Sainsbury's Customer Services role pulled into a Sainsbury's application).

## Step 9: Render and commit the variant to the private repo

There is **no Dockerfile or CircleCI change** for new variants. The public `lukeblaney_cv` Dockerfile only renders `cv-extended.md` and `cv.md` (the source-of-truth + the general-purpose CV). Per-JD variants are rendered via the helper script `~/sandboxes/lukeblaney_cv/render-tailored.sh`, which by default outputs only the .docx in the same directory as the source. Pass `--pdf` (before the markdown path) only when a specific application or recipient asks for a PDF.

```bash
~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md
```

The script reuses the same pandoc templates and brand colour as the public-repo build, so the rendered tailored CV looks identical in styling to a CV built from `cv.md`. Because the source is named `cv.md`, the script outputs `Luke Blaney - CV.docx` — a submission-ready filename that includes Luke's name (recruiters bulk-download CVs and they're unidentifiable in a Downloads folder otherwise). See Step 10 for verification.

**Commit everything together in a single commit** in `lukeblaney_cv_tailored`. Per `feedback_cv_commit_discipline.md`: variant creation is one piece of work, not many. Stage:

- The new `orgs/{company-slug}/{role-slug}/cv.md` (markdown source)
- The new `orgs/{company-slug}/{role-slug}/Luke Blaney - CV.docx` (submission artefact — committed alongside the markdown as the durable record of what was sent)
- Any new `orgs/{company-slug}/notes.md` if this is a first-time application to that company

Any `.pdf` ("Luke Blaney - CV.pdf") produced via `--pdf` is gitignored — regenerable for human review or hand-share if an application explicitly asks for one; not the canonical submission artefact.

Because the private repo doesn't carry the public-employer-name constraint, the commit message **can** name the company freely. Suggested format:

> "Add {Company} {Role} tailored CV"
>
> *Body describes the JD-tuning approach, the standard cuts applied, and any specific framing decisions. Naming the JD URL is fine.*

**Source-of-truth additions surfaced during the consultation** (e.g. a new bullet on `cv-extended.md` that should benefit all future variants) are still **their own commit in `lukeblaney_cv`**, BEFORE the variant commit. They're reusable; they get the small-commit treatment and follow the public-repo privacy rule (no employer names in `lukeblaney_cv` commits).

**Pre-flight before any commit to `lukeblaney_cv`**: the public repo accepts non-career-advisor commits (CircleCI / Dockerfile / Docker-image work) via a PR workflow, so the local working copy can end up on a feature branch or behind `origin/main`. Before editing or committing, run:

```bash
cd ~/sandboxes/lukeblaney_cv && git checkout main && git pull --ff-only origin main
```

The `lukeblaney_cv_tailored` repo doesn't have this issue — no PR workflow, career-advisor is the only writer.

## Step 10: Verify the rendered output

The render step in Step 9 produces `Luke Blaney - CV.docx` (the ATS submission artefact) in the role-slug directory. **Verify against the .docx** — its layout (Word/LibreOffice's, not LaTeX's) is what determines true page count for ATS purposes. (If `--pdf` was passed, a LaTeX-rendered `Luke Blaney - CV.pdf` will also exist, but its page count can differ from the .docx's by a page or more and is not authoritative.) Round-trip the .docx → PDF via LibreOffice in docker, then run the Python verification on that intermediate PDF. The verification uses `pdfminer.six` in a dedicated venv at `/tmp/pdfvenv`; the bootstrap line below is idempotent — it only does the install on first use and is a no-op afterwards:

```bash
# Bootstrap pdfvenv if not present
[ -x /tmp/pdfvenv/bin/python3 ] || (python3 -m venv /tmp/pdfvenv && /tmp/pdfvenv/bin/pip install -q pdfminer.six)

# Round-trip .docx → PDF via LibreOffice in docker
DIR="/home/lucas.linux/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}"
docker run --rm -v "$DIR:/data" --entrypoint /bin/bash linuxserver/libreoffice:latest \
  -c "libreoffice --headless --convert-to pdf --outdir /tmp '/data/Luke Blaney - CV.docx' >/dev/null 2>&1 && cp '/tmp/Luke Blaney - CV.pdf' '/data/Luke Blaney - CV (from docx).pdf'"

/tmp/pdfvenv/bin/python3 <<'EOF'
from pdfminer.pdfparser import PDFParser
from pdfminer.pdfdocument import PDFDocument
from pdfminer.pdfpage import PDFPage
from pdfminer.high_level import extract_text
import re

# Use the LibreOffice-rendered PDF for page count + content checks — reflects actual .docx layout.
path = '/home/lucas.linux/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/Luke Blaney - CV (from docx).pdf'
with open(path,'rb') as f:
    pages = list(PDFPage.create_pages(PDFDocument(PDFParser(f))))
text = extract_text(path)
print(f'DOCX pages: {len(pages)}, words: {len(text.split())}')
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

The `Luke Blaney - CV (from docx).pdf` file is a verification artefact, not a deliverable — `lukeblaney_cv_tailored`'s `.gitignore` already excludes `*.pdf` so it won't be staged.

Targets:
- **DOCX pages**: hard limit 3, target ~2.
  - If 4+: propose cuts and re-render before showing Luke. Standard cuts in priority order: drop Publications, drop Talks & Panels (or trim to 2 entries), trim Architect-Content bullets to 4, collapse Platform Architect to intro + 2 bullets, tighten Career Break, combine Director + Interim VP entries if a single intro line works.
  - If exactly 3: ask Luke whether to keep at 3 or push toward 2. Don't unilaterally cut more — pushing to 2 may require dropping JD-relevant content (Talks & Panels, multi-bullet roles) and Luke should decide the trade-off.
- **cid / ligs / hyphens**: all 0 (these are non-negotiable; if any are >0 the geometry/header is broken)
- **JD keywords**: all top-tier keywords present

(The LaTeX-PDF (`Luke Blaney - CV.pdf`) is only produced when `render-tailored.sh --pdf` is invoked; even then it's for human review only and its page count is not authoritative for the submission. See [[cv-page-count]].)

## Step 11: Push and report

```bash
cd ~/sandboxes/lukeblaney_cv_tailored && git push origin main
# Plus: cd ~/sandboxes/lukeblaney_cv && git push origin main  — only if Step 9 produced a source-of-truth commit there
```

Report back to Luke with:

- **File path** of the new variant (`~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md`)
- **Path of the committed .docx**: `…/{role-slug}/Luke Blaney - CV.docx` — this is the file to upload to the ATS (submission-ready filename)
- **Final page count and word count**
- **ATS metrics** (cid / ligs / hyphens all 0)
- **JD keyword check** (which top keywords confirmed present)
- **Commits applied**, naming both repos if `cv-extended.md` was also updated
- **Any new content added to cv-extended.md** during Step 5 — call this out so Luke knows the source-of-truth was updated
- (Mention the `--pdf` flag only if Luke asked for a PDF; default is docx-only.)

If Luke needs to regenerate later (e.g. after a cv-extended.md change), the manual path is:

```bash
~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md
# add --pdf before the path if a PDF is also needed
```

…then `git add` the regenerated `Luke Blaney - CV.docx` and commit.

## Git identity

All commits use the career-advisor GitHub App. Use the standard wrappers:

```bash
~/sandboxes/lucos_agent/git-as-agent --app career-advisor commit -m "..."
~/sandboxes/lucos_agent/gh-as-agent --app career-advisor ...
```

Commit directly to `main` on both `lukeblaney_cv` and `lukeblaney_cv_tailored` — neither has a PR/review workflow. See `feedback_cv_commit_discipline.md` for full discipline (small commits, source-only, gitignore artefacts).

## When this skill is not the right tool

- **The user wants to update cv-extended.md without a JD context** — that's just a normal career-advisor edit; do it inline.
- **The user wants a cover letter** — out of scope for this skill. A separate `/cover-letter` skill could be built later.
- **The JD URL is for a role Luke is firmly not applying for and just wants analysis** — do Steps 1-4 only and stop; don't build a variant.
- **No `cv-extended.md` exists, or it has obvious structural problems** — fix cv-extended.md first as a separate piece of work.
