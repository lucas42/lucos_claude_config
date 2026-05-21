---
name: tailor
description: Build a JD-tuned CV (and optionally a matching cover letter) for Luke in a single coordinated pass. Fetches the JD once; runs a joint analysis, gap consultation, and positioning-decisions step so framing, evidence, and tone stay coherent across both documents. Interactive throughout.
disable-model-invocation: false
---

Coordinated tailoring of both Luke's CV and his cover letter against a single JD. The two artefacts are produced together so that one set of positioning decisions cascades to both — Summary paragraph and letter opener share the same level-framing, Skills section and letter evidence story emphasise the same JD signals, CV career-break section and letter career-break aside say the same thing in the same voice.

The JD URL is provided as the first argument (e.g. `/tailor https://jobs.ashbyhq.com/...`). If no URL is provided, ask Luke for one — or for the JD text directly if the source isn't web-accessible.

## Step 0: Routing

This is career-advisor work — uses the career-advisor GitHub identity for commits, follows career-advisor memory conventions, writes career-advisor agent memories when new information surfaces.

- **If you are the career-advisor agent**: follow the steps below directly.
- **If you are any other agent**: send a message to the `career-advisor` teammate:
  > "tailor {url}"

  Then wait for the career-advisor to report back. Do not perform the work yourself.

## Step 1: Ask whether to also generate a cover letter

This skill **always generates a tailored CV**. Ask Luke up-front whether to also generate a cover letter for the same JD.

Use `AskUserQuestion`:
- "CV + cover letter" (default / recommended) — runs the full coordinated flow
- "CV only" — runs the CV path; letter-specific sub-steps marked `[LETTER]` below are skipped

Sub-steps marked `[LETTER]` are no-ops when "CV only" is chosen. Everything else runs identically. Choosing CV-only doesn't significantly simplify the flow — the joint analysis still happens — but it skips letter drafting, library propagation paths specific to letters, and the cross-document consistency check.

## Step 2: Load standing rules, pre-confirmed Luke-facts, library, and source-of-truth

**Standing rules** (hard constraints):

Apply to everything drafted:
- `~/.claude/agent-memory/career-advisor/feedback_cv_commit_discipline.md`
- `~/.claude/agent-memory/career-advisor/feedback_cv_copy_editing_scope.md`
- `~/.claude/agent-memory/career-advisor/feedback_cv_dialect_preference.md`
- `~/.claude/agent-memory/career-advisor/feedback_cv_variant_content_rule.md`
- `~/.claude/agent-memory/career-advisor/feedback_cv_application_privacy.md`

`[LETTER]` extra rules:
- `~/.claude/agent-memory/career-advisor/feedback_luke_voice.md` — banned words ("leverage", "AI Native", "synergies", "step change", "unlock value", "transformational"), no fake-passion claims, measured/dry register
- `~/.claude/agent-memory/career-advisor/feedback_cover_letter_standalone.md` — every sentence parseable without the CV
- `~/.claude/agent-memory/career-advisor/feedback_overlap_years_claim.md` — sum of "[N] years of [domain]" claims must not exceed ~15 years (Luke's actual tenure)

**Pre-confirmed Luke-facts** (don't re-ask things settled here):
- `~/.claude/agent-memory/career-advisor/user_skills_inventory.md` — defensible languages, databases, methodologies; what Luke claims and doesn't
- `~/.claude/agent-memory/career-advisor/user_role_framing.md` — level-positioning, manager-vs-IC tilts, career-break voice
- `[LETTER]` `~/.claude/agent-memory/career-advisor/user_cover_letter_patterns.md` — observed patterns from past letters; what's working, what isn't

**Project context and references**:
- `~/.claude/agent-memory/career-advisor/project_cv_rebuild.md`
- `[LETTER]` `~/.claude/agent-memory/career-advisor/project_cover_letter_rebuild.md`
- `~/.claude/agent-memory/career-advisor/reference_ashby_job_board_api.md`

**`[LETTER]` The library**:
- `~/sandboxes/lukeblaney_cv/cover-letters/template.md` — 4-paragraph structural template + rules
- `~/sandboxes/lukeblaney_cv/cover-letters/blocks/openers.md`
- `~/sandboxes/lukeblaney_cv/cover-letters/blocks/evidence-stories.md`
- `~/sandboxes/lukeblaney_cv/cover-letters/blocks/current-focus.md`
- `~/sandboxes/lukeblaney_cv/cover-letters/blocks/career-break-aside.md`
- `~/sandboxes/lukeblaney_cv/cover-letters/blocks/closes.md`

**Source of truth for the CV**:
- `~/sandboxes/lukeblaney_cv/cv-extended.md`

## Step 3: Fetch the JD (once, shared)

**Fetch the JD only once for the session.** The same content drives both CV and letter analysis.

Identify the ATS from the URL pattern:

- **Ashby** (`jobs.ashbyhq.com/{org}/{uuid}`): `curl -s "https://api.ashbyhq.com/posting-api/job-board/{org}?includeCompensation=true"` returns all jobs; filter for the matching `id`. The per-job endpoint returns 401 — don't use it.
- **Greenhouse** (`boards.greenhouse.io/{board}/jobs/{id}` or `job-boards.greenhouse.io/{board}/jobs/{id}`): `curl -s "https://boards-api.greenhouse.io/v1/boards/{board}/jobs/{id}"`. Some company-board URLs use a redirect (e.g. `partnerize.com/company/jobs?gh_jid=ID`) — the `gh_jid` is the job id; probe board names with `curl -o /dev/null -w "%{http_code}\n"` to find the right one.
- **Lever** (`jobs.lever.co/{company}/{id}`): `curl -s "https://api.lever.co/v0/postings/{company}/{id}"`.
- **Workday / iCIMS / Taleo / generic**: try WebFetch first. If thin content comes back, ask Luke to paste the JD text.

Extract:
- Role title and seniority level
- Company name, team or department, location, employment type
- Full JD text (responsibilities + requirements + nice-to-haves + culture blurb)
- Salary / compensation if disclosed

## Step 4: Joint JD analysis

Present a single combined analysis covering everything both documents need. Luke signs off once.

1. **Role archetype** — IC / manager / hybrid; junior / mid / senior / staff / principal / director / head / VP. Cite the phrases that signal this.
2. **Top-weighted JD signals** — the 3–5 things the JD cares about most. These guide:
   - The CV's Summary paragraph and Skills section ordering
   - The letter's opener choice, evidence story, "why this role" framing `[LETTER]`
3. **Hard requirements** — must-have qualifications, years, certifications, languages, location/visa. Flag any weak/missing in cv-extended.md.
4. **Tone calibration** — does the JD use banned buzzwords ("AI Native", "transformational")? Flag how to engage with the underlying ambition without parroting.
5. **Tech-stack overlap** — which JD-named tech Luke can claim per `user_skills_inventory.md`, which he can't. Flag gaps that need honest framing or genuine consultation.
6. **ATS keywords** — explicit programming languages, frameworks, methodologies, tools, domain terms. These populate the CV's Skills section.
7. **Inferred priorities** — what does the JD imply about company stage, team challenges, hiring-manager pain?

Pause for Luke to confirm the analysis lands. Especially flag any unusual or buzz-heavy framing — Luke may have a view on how authentically to match it.

## Step 5: Check for existing tailored content

Before drafting anything in the private repo:

1. **Company notes**: look for `~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/notes.md`. If it exists, read it for cross-application context (hiring manager name, recruiter contact, prior outcomes, ATS in use).
2. **Existing tailored CV for this role**: look for `~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md`. If found, this is a repeat invocation — ask Luke whether to overwrite or start fresh under a different role-slug.
3. **`[LETTER]` Existing cover letter for this role**: look for `…/{role-slug}/cover-letter.md`. Same handling.

If any of these exist, surface them to Luke before continuing. Default is reuse / overwrite the existing role-slug; only start fresh if Luke says so.

## Step 6: Joint strengths / gaps mapping

Read `~/sandboxes/lukeblaney_cv/cv-extended.md` and produce a single strengths/gaps table covering both documents:

- **For each top JD signal**: name the CV bullet(s) in cv-extended.md and `[LETTER]` the evidence-story candidate(s) from `evidence-stories.md` that map to it.
   - If both exist: framing is strong; signal is well-covered.
   - If only CV bullets exist (no library story): `[LETTER]` flag that the letter para 2 will need bespoke prose (or that a new library story should be drafted via Step 12).
   - If only library stories exist (no CV bullet): the CV may benefit from a new bullet — flag for cv-extended.md addition in Step 12.
- **Weak / missing**: hard or important requirements with no evidence in cv-extended.md or no matching library story. These are the gaps to consult Luke on in Step 7.

Present the single combined table before continuing.

## Step 7: Gap consultation (one joint pass)

**Critical: before asking Luke anything, check the pre-confirmed facts loaded in Step 2.** Don't re-ask things settled in `user_skills_inventory.md` or `user_role_framing.md`.

Ask Luke about genuine gaps only. Each new fact Luke confirms cascades to **both** documents — that's the leverage of the joint flow:

- A new defensible tech / language → goes into the CV's Skills section **and** can be referenced in the letter
- A new framing rule → applies to both the CV Summary and the letter opener
- A new evidence detail (e.g. specific outcome on the UPP story) → can sharpen both a CV bullet and an evidence-stories library block
- A new piece of company-level context (hiring manager name, prior contact) → goes into company notes

**When Luke provides new information to fill a gap**:

1. Use it in both documents being built.
2. Default-save to a user-type memory unless trivially obvious or ephemeral:
   - Tech / language / methodology defensibility → append to `user_skills_inventory.md`
   - Level-positioning / framing / voice → append to `user_role_framing.md`
   - One-line notification to Luke as a courtesy; don't block on confirmation for stable facts.
3. Also consider whether the new fact should land in:
   - `cv-extended.md` (CV-level achievement / new bullet — benefits all future variants)
   - `evidence-stories.md` `[LETTER]` (new story shape — benefits all future letters)
   These are their own commits BEFORE the per-application work — see Step 12.

## Step 8: Joint positioning decisions (the cross-pollination centrepiece)

This is the step that makes the combined skill more valuable than running the two skills sequentially. A single set of decisions determines the framing of BOTH documents, so they end up coherent rather than each reinventing the wheel.

Present each decision to Luke and get sign-off before drafting prose:

### 1. Level-positioning (per `user_role_framing.md`)

Where does this role sit relative to Luke's most recent title (Cyber Security Director, FT)?

- **Director-track** (Director / Head / VP of Engineering): lean into multi-team leadership; pull architecture experience up the page; soften "manager of managers" to "through senior tech and team leads"
- **Director-equivalent with technical authority** (Director of Engineering with explicit hands-on architecture expectations): hybrid framing; lead with both leadership scope and architectural depth
- **IC-track** (Staff Engineer, Principal Engineer, Architect): "deliberate technical re-focus" narrative; pull unbackfilled-PE bullet to the front of Director / Interim VP entries; surface architecture above strategy
- **EM / Tech Lead Manager**: "leading through senior leads" middle-ground framing

This decision cascades to:
- **CV Summary** positioning (Step 9)
- **CV bullet order** in Director / Interim VP entries
- **`[LETTER]` Letter opener pattern** from `openers.md` (cyber leadership / platform leadership / Director-of-Engineering / IC / EM)
- **`[LETTER]` Letter para 3** framing on level

### 2. Narrative tilt

Pick one based on the JD's strongest signal:

- **Security-flavoured** (cyber, GRC, AppSec, IAM, cloud-security)
- **Platform-engineering-flavoured** (platform, DevEx, SRE leadership, internal-tools)
- **Engineering-leadership-generalist** (EM, Director / Head / VP of Engineering at a SaaS company without security or platform specialism)
- **IC-architect** (Staff / Principal / Architect IC roles)

Cascades to:
- **CV Skills section** category ordering (which categories lead)
- **`[LETTER]` Letter current-focus variant** from `current-focus.md` (security / platform-engineering / generalist-leadership)
- **`[LETTER]` Letter evidence story** selection (per the cheat sheet at the bottom of `evidence-stories.md`)

### 3. Year-claims framing (per `feedback_overlap_years_claim.md`)

How many years of cyber security leadership vs software engineering / platform leadership does this application claim? The same role-period (Principal Engineer, Feb 2018 – Mar 2022) can count for cyber **or** for software engineering in any given document, but not both. Settle once across both documents:

- "5 years cyber security leadership" (PE period counts as cyber) — for JDs where cyber is the strength
- "3 years cyber security leadership" (PE period counts as software engineering / platform) — for JDs that want engineering experience and less cyber

The chosen framing applies to the CV's Summary AND the letter's opener / evidence consistently.

### 4. Career-break treatment

- **CV**: standard `# Career Break & Current Focus` section between Summary and Skills. Lift the existing voice from cv-extended.md; flavour to match the chosen narrative tilt.
- **`[LETTER]` Letter**: default one-line aside embedded in paragraph 4. Promote to a sentence only if the JD's domain (transport, travel, internationally-distributed team) specifically warrants it.

The voice should be consistent across both. Same lucos_agent / multi-persona LLM fleet framing, same banned-word avoidance.

### 5. Tone register

Measured / dry / slightly understated default. The CV's Summary paragraph and the letter's whole register should match.

### 6. `[LETTER]` Letter block selection

Final letter-specific choices, derived from decisions 1–5 above:

- **Opener pattern** — name the section and pattern from `openers.md` (e.g. "Director / Head / VP of Engineering > Hybrid leadership + technical authority")
- **Evidence story** — primary story by number and name (e.g. `#3 Universal Publishing Platform`); secondary only if there's word budget. Use the Story-selection cheat sheet at the bottom of `evidence-stories.md`.
- **Current-focus variant** — security / platform-engineering / generalist-leadership flavour from `current-focus.md`
- **Close** — default warmer/inviting from `closes.md`

Confirm the full set of decisions with Luke before drafting prose. This is the single biggest sign-off gate in the flow.

## Step 9: Propose CV drafts

Per `feedback_cv_copy_editing_scope.md`, any new copy needs consultation. Show Luke draft text for the CV:

1. **Summary line / paragraph** (2–4 sentences positioning him for this specific role). Must agree in level-positioning, narrative tilt, and tone register with what the letter will say in its opener.
2. **Career Break / Current Focus section** — adapt the existing voice; flavour to match the chosen narrative tilt.
3. **Skills section** — grouped categories, comma-separated keywords, JD-tuned. Candidate categories: Engineering Leadership, Architecture & Distributed Systems, Programming & Systems, Engineering Practice, Cloud & Platform, Cyber Security, Data & Platform, Generative AI. Reorder or substitute based on the JD.
4. **Bullet reframes** — bullets to reorder, expand, or rephrase. Pay particular attention to bullets that overlap with the letter's evidence story: if the letter centres on a specific story, the corresponding CV bullets should match its emphasis.

Get sign-off on each block before continuing.

## Step 10: Propose letter draft `[LETTER]`

Draft all four paragraphs in a single pass, applying the joint positioning decisions from Step 8 and consistent with the CV Summary signed off in Step 9. Don't show Luke until the assembled letter is ready — he prefers reviewing the whole letter rather than paragraph-by-paragraph.

1. **Paragraph 1 (Anchor, 40–60 words)** — based on the chosen opener pattern. Must stand alone per `feedback_cover_letter_standalone.md`.
2. **Paragraph 2 (Evidence, 80–120 words)** — pull the chosen story from `evidence-stories.md`; adapt to the JD's specific signals. Don't quote verbatim — treat the library as a starting point.
3. **Paragraph 3 (Why this role / company, 60–100 words)** — bespoke. Default to writing about why the *role-shape* is interesting, not the company's mission, unless Luke surfaced specific knowledge of the company in Step 4 or Step 7.
4. **Paragraph 4 (Current focus + close, 80–130 words)** — start with the chosen current-focus variant from `current-focus.md`. Embed the career-break aside per Step 8 (single phrase, not its own sentence by default). End with the chosen close.

## Step 11: Self-checks

Before showing Luke the final assembled output, run the checks below. Fix any failure before showing.

**CV**:
- Page count target 3 (acceptable: 2). Anything over 3 → propose further cuts.
- ATS metrics (from Step 14 verification): `cid` / `ligs` / `hyphens` all 0 (non-negotiable)
- JD top keywords: all present in the rendered text

**Letter** `[LETTER]`:
- **Banned words scan**: "leverage", "AI Native", "synergies", "step change", "unlock value", "transformational", "genuinely motivated", "deeply passionate". Any hit → revise.
- **Standalone-ness check**: each sentence parseable without the CV.
- **Word count**: target 250–350; 400 ceiling for senior roles with substantive technical content.
- **Overlap-years check**: sum of "[N] years of [domain]" claims in the letter ≤ ~15 years.
- **Dialect check**: no Americanisms (`-ize`, "organization", "color", "behavior", "math", "specialty").
- **Salutation present**, **close + sign-off present**.

**Cross-document consistency** (when generating both):
- Level-positioning in CV Summary and letter opener must match (e.g. both IC-track, or both Director-track).
- Narrative tilt consistent across both.
- Career-break treatment consistent: CV section and letter aside say the same thing in the same voice.
- Current-focus framing (lucos_agent / multi-persona LLM fleet) described in the same register in both.
- Year-claims totaled in the letter alone must not exceed ~15 years; the CV is structured (dates listed by role) so internal consistency isn't at risk there.

## Step 12: Upstream propagation

Before committing the per-application work, scan the session for content worth propagating back so future invocations inherit it.

For each piece of new content surfaced:

1. **New defensible skill / language / methodology Luke confirmed**
   → append to `~/.claude/agent-memory/career-advisor/user_skills_inventory.md`
   → default-save with a one-line notification

2. **New framing / level-positioning rule Luke confirmed**
   → append to `~/.claude/agent-memory/career-advisor/user_role_framing.md`
   → default-save

3. **New banned word / voice rule / tone preference Luke surfaced**
   → append to `~/.claude/agent-memory/career-advisor/feedback_luke_voice.md`
   → default-save

4. **`[LETTER]` A library-level fix surfaced through use** (e.g. an opener pattern that turned out to assume CV context)
   → propose for edit to `~/sandboxes/lukeblaney_cv/cover-letters/blocks/{block}.md`
   → ask Luke for sign-off on exact wording
   → its own commit BEFORE the per-application work

5. **`[LETTER]` A new evidence-story-shape Luke confirmed** (or a gap-fill detail that sharpens an existing story)
   → propose for addition/edit to `evidence-stories.md`
   → sign-off on exact wording
   → its own commit before the application

6. **`[LETTER]` A new opener pattern or current-focus variant**
   → propose for addition to relevant block file
   → sign-off on wording
   → its own commit before the application

7. **A new CV-level achievement** (accomplishment that should appear on every CV variant)
   → propose for addition to `~/sandboxes/lukeblaney_cv/cv-extended.md`
   → sign-off on exact wording
   → its own commit before the per-application work so future `/tailor` and `/tailor-cv` invocations inherit it

8. **Company-level context** (hiring manager name, recruiter contact, ATS, prior interview history)
   → add to or update `orgs/{company-slug}/notes.md` in the private repo
   → bundled with the per-application commit in Step 13

**Default-save vs ask-for-sign-off**:
- Memory changes (categories 1–3): default-save, one-line notification.
- Library + `cv-extended.md` changes (categories 4–7): ask for sign-off on exact wording; each is its own commit BEFORE the per-application bundle.
- Company-notes (category 8): bundled in the per-application commit.

This step is what makes each application strengthen the system. Skip it and the same fixes get reinvented next time.

## Step 13: Write, render, and commit

**Working directory**: `~/sandboxes/lukeblaney_cv_tailored/`. If the clone isn't present:

```bash
cd ~/sandboxes && git clone git@github.com:lucas42/lukeblaney_cv_tailored.git
```

**Directory structure**:
- `orgs/{company-slug}/notes.md` — company-level context + per-role sections
- `orgs/{company-slug}/{role-slug}/cv.md` — CV variant
- `[LETTER]` `orgs/{company-slug}/{role-slug}/cover-letter.md` — letter

Slug rules: lowercase-kebab of company name; lowercase-kebab of role title.

### Write the CV variant

Start from `~/sandboxes/lukeblaney_cv/cv-extended.md`. Apply:

1. Add Summary section between contact block and Employment
2. Add Career Break & Current Focus section (before Skills)
3. Add Skills section with JD-tuned grouped keywords
4. Apply role-specific bullet reframes per Step 9

Apply the standard cuts (variants land at 3 pages by default):

1. **Collapse adjacent Principal Engineer entries** — cv-extended.md has three PE entries covering Feb 2018 – Mar 2022. Combine into a single entry titled `## Principal Engineer - Reliability Engineering, Cyber Security, Observability & Edge Delivery` with dates `Financial Times: February 2018 - March 2022`. Keep 5–7 best bullets across the three.
2. **Compress oldest roles to Earlier Career** — roles 10+ years old become one-liners (Labs Developer at FT Labs, Web Developer at Assanka). Format: `- Company - **Role**: dates`.
3. **Trim Talks & Panels to top 4** — keep JD-relevant entries.
4. **Drop reflective closing paragraphs** in non-recent role entries.
5. **Drop Education's A-levels and GCSEs**.
6. **Drop `# Earlier Career` (pre-Assanka) and `# Positions of Responsibility`** unless individual entries are directly relevant to the target employer/industry (per `feedback_cv_variant_content_rule.md`).

### `[LETTER]` Write the letter

YAML frontmatter for internal metadata, then 4-paragraph body in plain markdown. **No `# Cover letter — …` H1** in the body (would render as a giant purple heading).

```markdown
---
role: {role title from JD}
company: {company name}
drafted: {YYYY-MM-DD}
library-source: lucas42/lukeblaney_cv/cover-letters/
opener-pattern: {section > pattern}
evidence-story: "#N {story name}"
current-focus-variant: {flavour}
---

Dear {salutation},

{body paragraphs 1–4}

Kind Regards,

Luke Blaney
```

### Update or create notes.md

- If `notes.md` exists: append a new role section under `## Roles applied for`. Don't duplicate company-level notes.
- If not: create with company-level notes (industry, ATS, public job-board URL, API endpoint if useful) + first role section.

### Render

```bash
~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md
# [LETTER]:
~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cover-letter.md
```

Outputs (in the role-slug directory):
- `Luke Blaney - CV.docx` (committed, ATS-ready submission name)
- `Luke Blaney - CV.pdf` (gitignored, for human review)
- `[LETTER]` `Luke Blaney - Cover Letter.docx` (committed)
- `[LETTER]` `Luke Blaney - Cover Letter.pdf` (gitignored)

### Commit

**Single bundled commit** covering everything from this application — `cv.md`, `Luke Blaney - CV.docx`, `cover-letter.md` (if present), `Luke Blaney - Cover Letter.docx` (if present), and the new/updated `notes.md`. Per `feedback_cv_commit_discipline.md`, application work is one commit (not split). Commit message can name the company freely — this is the private repo per `feedback_cv_application_privacy.md`.

Suggested commit message:
> "Add {Company} {Role} tailored CV [and cover letter]"
>
> Body summarising the joint positioning decisions (level, narrative tilt, year-claims framing), letter opener pattern + evidence story used (if letter), any honest-gap framings applied, and any cross-document consistency choices worth noting.

**Source-of-truth additions surfaced during the consultation** (memory updates from Step 12 categories 1–3 are default-saved without commits — they're memory files. Library / cv-extended.md changes from categories 4–7 are their own commits in `lukeblaney_cv`, BEFORE the per-application commit in `lukeblaney_cv_tailored`.)

### Push

```bash
cd ~/sandboxes/lukeblaney_cv_tailored && git push origin main
# Plus if Step 12 produced library / cv-extended.md commits:
cd ~/sandboxes/lukeblaney_cv && git push origin main
```

## Step 14: Verify the rendered CV

Run the Python verification on the rendered PDF:

```bash
/tmp/pdfvenv/bin/python3 <<'EOF'
from pdfminer.pdfparser import PDFParser
from pdfminer.pdfdocument import PDFDocument
from pdfminer.pdfpage import PDFPage
from pdfminer.high_level import extract_text
import re

path = '/home/lucas.linux/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/Luke Blaney - CV.pdf'
with open(path,'rb') as f:
    pages = list(PDFPage.create_pages(PDFDocument(PDFParser(f))))
text = extract_text(path)
print(f'Pages: {len(pages)}, words: {len(text.split())}')
print(f'cid={len(re.findall(r"(cid:\\d+)", text))}  '
      f'ligs={sum(text.count(c) for c in [chr(0xFB01),chr(0xFB02),chr(0xFB00)])}  '
      f'hyphens={len(re.findall(r"\\w-\\n\\w", text))}')

jd_keywords = [...]  # substitute top keywords from Step 4
lower = text.lower()
missing = [k for k in jd_keywords if k not in lower]
print(f'JD keywords missing: {missing if missing else "none"}')
EOF
```

Targets:
- **Pages**: 3 (acceptable: 2). If 4+, propose further cuts before committing.
- **cid / ligs / hyphens**: all 0 (non-negotiable — if any are >0 the geometry/header is broken).
- **JD keywords**: all top-tier keywords present.

If page count is over 3, propose cuts (drop Talks & Panels; combine Director + Interim VP into one entry; tighten Career Break; trim less-differentiating bullets in recent roles).

## Step 15: Report back

Tell Luke:

**CV artefacts**:
- Source path: `~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md`
- ATS upload (.docx): `…/Luke Blaney - CV.docx`
- PDF (gitignored): `…/Luke Blaney - CV.pdf`
- Page count, word count, ATS metrics, JD keyword check result

**`[LETTER]` Letter artefacts**:
- Source path: `…/cover-letter.md`
- ATS upload (.docx): `…/Luke Blaney - Cover Letter.docx`
- PDF (gitignored): `…/Luke Blaney - Cover Letter.pdf`
- Word count, library blocks used (opener, story, current-focus variant)

**Joint positioning summary** — what was decided at Step 8:
- Level-positioning
- Narrative tilt
- Year-claims framing
- Career-break treatment
- Tone register

**Upstream propagation that landed**: list each commit in `lukeblaney_cv` or `~/.claude` (with one-line summary), plus any default-saved memory changes from Step 12.

**Any new memory captured** during the session, so Luke knows what's been saved for future invocations.

**Suggested submission route**: upload both `.docx` files to the ATS as file attachments. Most ATSes provide separate upload fields for the CV and cover letter.

If Luke needs to regenerate later (e.g. after a red-line edit):

```bash
~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md
# and/or
~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cover-letter.md
```

…then `git add` the regenerated `.docx` and commit.

## Git identity

All commits use the career-advisor GitHub App. Use the standard wrappers:

```bash
~/sandboxes/lucos_agent/git-as-agent --app career-advisor commit -m "..."
~/sandboxes/lucos_agent/gh-as-agent --app career-advisor ...
```

Commit directly to `main` on both `lukeblaney_cv` and `lukeblaney_cv_tailored` — neither has a PR/review workflow.

## When this skill is not the right tool

- **Luke wants only a CV, no letter** — still use `/tailor` and answer "CV only" at Step 1. Or invoke `/tailor-cv` directly for the leaner standalone flow.
- **Luke wants only a letter, no CV** — use `/tailor-cover-letter` directly. This skill always generates a CV.
- **Luke wants to update the cover-letter library or `cv-extended.md` itself** (add a new story, change the template, rewrite an opener) — that's a normal career-advisor edit, not a per-application task. Skip the JD-analysis steps.
- **Luke wants analysis of a JD without producing artefacts** — do Steps 1–6 and stop; don't write any files.
- **No JD URL or JD text is available** — ask Luke for one before starting.
- **The company has a closed application that Luke isn't reopening** — confirm with Luke whether to draft fresh material or just update the company-notes outcome field.

## Relationship to `/tailor-cv` and `/tailor-cover-letter`

This skill deliberately duplicates much of the logic of `/tailor-cv` and `/tailor-cover-letter` in order to interleave the consultation steps and maximise cross-pollination between the two documents (the explicit reason the combined skill exists). The single-purpose skills remain useful when Luke wants a leaner standalone flow.

**When updating standing rules or workflow logic**:
- If you change material rules in `/tailor-cv` (positioning rules, standard cuts, file structure, render path) or `/tailor-cover-letter` (block-selection logic, voice rules, file structure, render path), remember to mirror the change here.
- The skills share the same memory files (`user_skills_inventory.md`, `user_role_framing.md`, etc.) and the same library (`cover-letters/blocks/`) and the same source-of-truth (`cv-extended.md`). Updates to those files automatically benefit all three skills — that's where most of the durable logic lives.
