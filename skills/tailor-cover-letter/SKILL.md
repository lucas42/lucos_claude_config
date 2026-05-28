---
name: tailor-cover-letter
description: Draft a JD-tuned cover letter for Luke using the building-block library at lukeblaney_cv/cover-letters/. Interactive — proposes paragraphs for sign-off, self-checks against Luke-voice and standalone-ness rules, commits the draft to the private lukeblaney_cv_tailored repo.
disable-model-invocation: false
---

Draft a cover letter for a specific job application, derived from the building-block library at `~/sandboxes/lukeblaney_cv/cover-letters/`.

The JD URL is provided as the first argument (e.g. `/tailor-cover-letter https://jobs.ashbyhq.com/...`). If no URL is provided, ask Luke for one — or for the JD text directly if the source isn't web-accessible.

## Step 0: Routing

This is career-advisor work — uses the career-advisor GitHub identity for commits, follows career-advisor memory conventions, writes career-advisor agent memories when new information surfaces.

- **If you are the career-advisor agent**: follow the steps below directly.
- **If you are any other agent**: send a message to the `career-advisor` teammate:
  > "tailor-cover-letter {url}"
  
  Then wait for the career-advisor to report back. Do not perform the work yourself.

## Step 1: Load standing rules, library, and pre-confirmed Luke-facts

**Standing rules** (hard constraints on what I draft):

- `~/.claude/agent-memory/career-advisor/feedback_luke_voice.md` — banned words ("leverage", "AI Native", "synergies", "step change", "unlock value", "transformational"), no fake-passion claims about company missions Luke doesn't genuinely care about, measured/dry register
- `~/.claude/agent-memory/career-advisor/feedback_cover_letter_standalone.md` — every sentence must be comprehensible to a reader who hasn't seen the CV
- `~/.claude/agent-memory/career-advisor/feedback_overlap_years_claim.md` — sum of "[N] years of [domain]" claims must not exceed Luke's total working tenure (~15 years from Nov 2010)
- `~/.claude/agent-memory/career-advisor/feedback_cv_dialect_preference.md` — UK / Irish English; no Americanisms
- `~/.claude/agent-memory/career-advisor/feedback_cv_application_privacy.md` — default-deny on employer names in any public artefact. Employer names ARE allowed in the private `lukeblaney_cv_tailored` repo.
- `~/.claude/agent-memory/career-advisor/feedback_cv_commit_discipline.md` — small targeted commits; one bundled commit per new letter; source-only

**Pre-confirmed Luke-facts** (don't re-ask things settled here):

- `~/.claude/agent-memory/career-advisor/user_skills_inventory.md` — defensible languages/databases/methodologies; what Luke claims and doesn't
- `~/.claude/agent-memory/career-advisor/user_role_framing.md` — level-positioning, manager-vs-IC tilts, career-break voice
- `~/.claude/agent-memory/career-advisor/user_cover_letter_patterns.md` — observed patterns from past letters; what's working, what isn't

**Project context and references**:

- `~/.claude/agent-memory/career-advisor/project_cover_letter_rebuild.md` — including the company-notes convention
- `~/.claude/agent-memory/career-advisor/reference_ashby_job_board_api.md` — for fetching JD content from Ashby and notes on other ATS endpoints

**The library** (the source-of-truth for drafted content):

- `~/sandboxes/lukeblaney_cv/cover-letters/template.md` — 4-paragraph structural template + rules
- `~/sandboxes/lukeblaney_cv/cover-letters/blocks/openers.md`
- `~/sandboxes/lukeblaney_cv/cover-letters/blocks/evidence-stories.md`
- `~/sandboxes/lukeblaney_cv/cover-letters/blocks/current-focus.md`
- `~/sandboxes/lukeblaney_cv/cover-letters/blocks/career-break-aside.md`
- `~/sandboxes/lukeblaney_cv/cover-letters/blocks/closes.md`

## Step 2: Fetch the JD

Same ATS routing as `/tailor-cv` — see the Ashby reference memory for the standard endpoint patterns.

- **Ashby** (`jobs.ashbyhq.com/{org}/{uuid}`): `curl -s "https://api.ashbyhq.com/posting-api/job-board/{org}?includeCompensation=true"` returns all jobs as JSON; filter for the matching `id`. The per-job endpoint (`/posting-api/job-board/{org}/{job-id}`) returns 401 — don't use it.
- **Greenhouse** (`boards.greenhouse.io/{board}/jobs/{id}` or `job-boards.greenhouse.io/{board}/jobs/{id}`): `curl -s "https://boards-api.greenhouse.io/v1/boards/{board}/jobs/{id}"`.
- **Lever** (`jobs.lever.co/{company}/{id}`): `curl -s "https://api.lever.co/v0/postings/{company}/{id}"`.
- **Workday / iCIMS / Taleo / generic**: try WebFetch first. If thin content comes back, ask Luke to paste the JD text in the conversation.

Extract:

- Role title and seniority level
- Company name, team or department, location, employment type
- Full JD text (responsibilities + requirements + nice-to-haves + culture blurb)
- Salary / compensation if disclosed

### Probe the application form too

Same per-ATS API extension as in `/tailor` Step 3.5 — fetch the form structure to confirm what the cover-letter content should actually fill:

- **Greenhouse**: append `?questions=true` to the boards-api URL; check `questions[]` for `input_file` (Cover Letter) vs `textarea` fields ("Cover Letter", "Why X?", "Additional Information", or other custom-question textareas).
- **Lever**: posting JSON includes form metadata.
- **Ashby**: `applicationFormDefinition` in the posting-api response.
- **Workday / iCIMS / Taleo**: ask Luke to paste / describe form fields.

The cover-letter content drafted by this skill may end up shaped as:
- a `.docx` cover letter (file-upload field present) — default rendering
- a single plain-text body (cover-letter textarea, no file alternative) — skip `.docx` render
- a set of per-question textarea answers (no cover-letter field at all, but content-bearing custom questions present) — split letter content across answers with disjoint coverage (see `/tailor` Step 10 Variant B for the per-question framing rules and Step 11 for the disjoint-content cross-check)

For any textarea-shaped artefact (Variant A textarea form-shape OR Variant B per-question answers), **include the scheme on URLs** (`https://example.com/path`, not `example.com/path`) — see [[textarea-url-scheme]]. Bare-host URLs only work in rendered formats where the display text and underlying link can differ.

If the form doesn't accept a cover letter in any shape AND has no custom content-bearing textareas, stop and ask Luke: there may be no useful artefact for this skill to produce on this application. Don't render an unused `.docx`.

## Step 3: Analyse the JD

Present a short analysis to Luke covering:

1. **Role archetype** — IC, manager, hybrid; Staff / Principal / Architect / EM / TLM / Director / Head / VP. Cite the phrases that signal this.
2. **Top-weighted JD signals** — the 3-5 things the JD cares about most (architecture, standards, team-formation, scale, specific tech, etc.). These guide opener choice and evidence-story selection.
3. **Tone calibration** — does the JD use buzzwords from the banned list (e.g. "AI Native")? If so, flag how I'll engage with the *underlying* ambition without parroting the phrase.
4. **Tech-stack overlap** — which languages / methodologies / tools does the JD mention, and which of these Luke can comfortably claim per `user_skills_inventory.md`. Flag any required tech Luke won't claim — this may need to be addressed via an honest gap note (see the regulated-pensions pattern).
5. **Inferred priorities** — what does the JD imply about company stage, team challenges, hiring-manager pain?

Pause here for Luke to confirm the analysis lands. Especially flag any unusual or buzz-heavy framing — Luke may have an opinion on how authentically to match it.

## Step 4: Map JD to library blocks

Propose the specific block choices for Luke's sign-off:

1. **Opener** — name the section and pattern from `openers.md` (e.g. "Cyber security leadership > Direct, JD-anchored", or "Architect / Principal Architect / Staff Engineer > Deliberate technical re-focus").
2. **Evidence story** — primary story by name and number (`#3 Universal Publishing Platform`, `#1 Technical standards rationalisation`, etc.) and, if there's room, a secondary. Use the `Story-selection cheat sheet` at the bottom of `evidence-stories.md` as a starting point.
3. **Current-focus variant** — security-flavoured / platform-engineering-flavoured / generalist-leadership-flavoured. Match the JD's emphasis.
4. **Career-break treatment** — default to one-line aside; promote to a sentence only if the company / role specifically warrants it (transport, travel, internationally-distributed team).
5. **Close** — pick from `closes.md`; default to "I'd welcome the chance to discuss this — happy to share more on any of the above."

Confirm the mapping with Luke before drafting prose.

## Step 5: Check for existing company-notes and tailored CV

Before writing anything in the private repo:

1. **Company notes**: look for `~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/notes.md`. If it exists, Luke has applied to this company before — read it for cross-application context (hiring manager name, recruiter contact, prior outcomes, ATS in use, etc.). If not, plan to create the directory and notes file.
2. **Tailored CV**: look for an existing `~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md` matching this role. If one exists, check its Summary section to keep the cover-letter framing consistent with the CV positioning. If no matching variant exists, consider whether `/tailor-cv` should be run first — flag this to Luke.

## Step 6: Draft all four paragraphs

Draft the full letter in one pass. Don't show Luke anything yet — the self-check in Step 7 catches voice and standalone issues, and Luke prefers to review the assembled letter as a whole rather than paragraph-by-paragraph.

1. **Paragraph 1 (Anchor, 40–60 words)** — based on the chosen opener pattern. **Critical**: must stand alone per `feedback_cover_letter_standalone.md`. The reader hasn't seen the CV. Do not use phrases like "the unbackfilled Principal Engineer responsibilities" that require CV-assembled context.

2. **Paragraph 2 (Evidence, 80–120 words)** — pull the chosen story from `evidence-stories.md` (short or long form depending on space). Adapt the prose to land on the JD's specific signals — if the JD emphasises mission-critical, lead with mission-critical; if it emphasises consultative leadership, lead with the bottleneck-to-consultative pivot. Don't quote the library verbatim; treat each story as a starting point.

3. **Paragraph 3 (Why this role/company, 60–100 words)** — **BESPOKE per application — no library**. By default, write about why the *role* is interesting (skill match, unusual combination of responsibilities, the specific problem space) rather than the company's mission. Never claim Luke is "genuinely motivated" by a company's mission unless he has explicitly confirmed it. If Luke has personal knowledge of the company (engineering blog content, conversations, a domain interest), ask him to provide it before drafting this paragraph rather than making things up.

4. **Paragraph 4 (Current focus + close, 80–130 words)** — start with the chosen `current-focus.md` variant, adapted lightly to engage with any JD-specific framing (without parroting banned words). Embed the career-break aside if appropriate, as a single phrase rather than its own sentence. End with the chosen close.

## Step 7: Self-check before final review

Once all four paragraphs have draft-level sign-off, assemble the full letter and run these checks BEFORE showing it to Luke for the final review:

1. **Banned words scan** — search for: "leverage", "AI Native", "synergies", "step change", "unlock value", "transformational", "genuinely motivated", "deeply passionate". Any hit → revise that sentence.
2. **Standalone-ness check** — read each sentence as if the CV doesn't exist. If any sentence requires CV-assembled facts to parse, rewrite.
3. **Word-count check** — target 250–350 words; 400 is the absolute ceiling for senior roles with substantive AI / technical content.
4. **Overlap-years check** — count up every "[N] years of [domain]" claim. Sum must not exceed Luke's actual working tenure (~15 years as of 2026). If two domains overlap (e.g. cyber + software engineering during the Principal Engineer period), the same role-period cannot count for both.
5. **Dialect check** — scan for Americanisms: `-ize` endings, "organization", "color", "behavior", "favorite", "analyzed", "specialty" (vs "speciality"), "math" (vs "maths").
6. **Salutation check** — does the letter open with "Dear [Name]"? If Luke has supplied a hiring manager name in the company-notes, use it; otherwise default to "Dear [Company] hiring team".
7. **Close check** — does the letter end with both a closing line *and* a sign-off?

If any check fails, fix before showing Luke.

## Step 8: Show Luke the assembled letter for review

Present the full letter inline. Note any decisions worth flagging:

- Word count
- Stylistic decisions made (e.g. how a JD buzzword was handled)
- Anything in paragraph 3 that you'd particularly like Luke to verify or rewrite
- Anything you weren't sure about during drafting

Be prepared for multiple rounds of red-lines. Luke's voice is voice-sensitive; the first draft is rarely the last.

## Step 9: Upstream propagation

Before committing the per-application letter, scan the session for content worth propagating back to the source — so future invocations of this skill (and `/tailor-cv`) inherit it.

For each piece of new content surfaced during the session, consider:

1. **New defensible skill / language / methodology Luke confirmed** (e.g. "I'd claim BDD as adjacent to TDD" surfacing during gap consultation)
   → append to `~/.claude/agent-memory/career-advisor/user_skills_inventory.md`
   → default-save with a one-line summary to Luke; doesn't block on confirmation for clearly-stable facts

2. **New framing / level-positioning rule Luke confirmed** (e.g. how to position a particular career period for a particular JD shape)
   → append to `~/.claude/agent-memory/career-advisor/user_role_framing.md`
   → default-save with a one-line summary

3. **New banned word, voice rule, or tone preference Luke surfaced** (e.g. red-lined a word with strong feeling, or rejected a phrasing as not-his-voice)
   → append to `~/.claude/agent-memory/career-advisor/feedback_luke_voice.md`
   → default-save with a one-line summary

4. **A library-level fix surfaced through use** (e.g. an opener pattern in `openers.md` that turned out to assume CV context and needed rewriting, like the "Deliberate technical re-focus" fix in 2026-05-20)
   → propose for edit to `~/sandboxes/lukeblaney_cv/cover-letters/blocks/{block}.md`
   → ask Luke for sign-off on exact wording before committing — this is library prose that Luke may want to red-line
   → commits as its own commit BEFORE the per-application letter commit, so future invocations inherit it

5. **A new evidence-story-shape Luke confirmed** (e.g. an achievement not yet in `evidence-stories.md` that turned out to be useful for this JD, or a gap-fill detail that sharpens an existing story like the SaaS migration counts in 2026-05-20)
   → propose for addition to `~/sandboxes/lukeblaney_cv/cover-letters/blocks/evidence-stories.md`
   → ask Luke for sign-off on exact wording
   → commits before the per-application letter

6. **A new opener pattern or current-focus variant that worked well** (e.g. a JD archetype or flavour not yet covered by the library)
   → propose for addition to the relevant block file
   → ask Luke for sign-off on exact wording
   → commits before the per-application letter

7. **A new CV-level achievement that surfaced** (e.g. an accomplishment Luke described during gap consultation that should appear on every CV variant, not just this letter)
   → propose for addition to `~/sandboxes/lukeblaney_cv/cv-extended.md`
   → get Luke's sign-off on exact wording
   → commits before the letter so future `/tailor-cv` invocations inherit it

8. **Company-level context** (e.g. hiring manager name, recruiter, ATS in use, anything cross-cutting that applies if Luke applies to this company again)
   → add to or update `orgs/{company-slug}/notes.md` in the private repo
   → commits as part of the per-application letter bundle in Step 10

**Pre-flight before any commit to `lukeblaney_cv`** (categories 4–7 above): the public repo accepts non-career-advisor commits (CircleCI / Dockerfile / Docker-image work) via a PR workflow, so the local working copy can end up on a feature branch or behind `origin/main`. Before editing or committing, run:

```bash
cd ~/sandboxes/lukeblaney_cv && git checkout main && git pull --ff-only origin main
```

The `lukeblaney_cv_tailored` repo doesn't have this issue — no PR workflow, career-advisor is the only writer.

**Default-save vs ask-for-sign-off**:
- Memory changes (categories 1–3): default-save with a one-line notification; Luke has explicitly OK'd this for stable facts.
- Library and `cv-extended.md` changes (categories 4–7): ask for sign-off on the exact wording — these are prose Luke might want to red-line. Each gets its own commit, BEFORE the per-application letter commit, so it's reusable.
- Company-notes (category 8): drafts within the per-application letter bundle.

This step is what makes each application strengthen the system. Skip it and the same fixes get reinvented next time.

## Step 10: Write, render, and commit to the private repo

Once Luke approves the final draft and any upstream propagation:

1. **Working directory**: `~/sandboxes/lukeblaney_cv_tailored/`. If the clone isn't present, clone it: `cd ~/sandboxes && git clone git@github.com:lucas42/lukeblaney_cv_tailored.git`. Per-org directories live under `orgs/`.
2. **Directory structure**:
   - `orgs/{company-slug}/notes.md` — company-level context + per-role sections. Slug is lowercase-kebab of the company name.
   - `orgs/{company-slug}/{role-slug}/cover-letter.md` — the letter draft for this specific role. `{role-slug}` is a lowercase-kebab subdirectory (e.g. `staff-software-engineer-short-term-credit/`) that holds both the cover-letter and the matching CV (`cv.md`). The filename inside is always `cover-letter.md` — role context comes from the directory.
3. **If `notes.md` already exists**: append a new role section under `## Roles applied for`. Don't duplicate company-level notes.
4. **If `notes.md` doesn't exist**: create it with company-level notes (industry, ATS, public job-board URL, API endpoint if useful) plus the role section.
5. **Letter file structure** — use YAML frontmatter for internal metadata so it doesn't render into the submitted document, then the 4-paragraph letter body in plain markdown. Example:

   ```markdown
   ---
   role: Staff Software Engineer (Short Term Credit)
   company: Funding Circle
   drafted: 2026-05-20
   library-source: lucas42/lukeblaney_cv/cover-letters/
   ---

   Dear Funding Circle hiring team,

   [opener paragraph...]

   [evidence paragraph...]

   [why-this-role paragraph...]

   [current-focus + close paragraph...]

   Kind Regards,

   Luke Blaney
   ```

   Do **not** put a `# Cover letter — ...` H1 at the top of the body — it would render as a giant purple heading on the submitted document. All metadata lives in YAML.

6. **Render the .docx submission artefact** via the helper script. Per `feedback_cover_letter_upload_field.md`, most ATSes take cover letters as file uploads, so the .docx is the primary submission format — produce it by default, not on demand.

   ```bash
   ~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cover-letter.md
   # add --pdf before the path if a PDF is also needed (rare — ATSes overwhelmingly want the .docx)
   ```

   Because the source is named `cover-letter.md`, the script outputs `Luke Blaney - Cover Letter.docx` (committed, the submission artefact with ATS-ready filename) by default. A `Luke Blaney - Cover Letter.pdf` is also produced if `--pdf` is passed — when deliberately invoked (e.g. a recruiter has asked for a PDF for direct share) that PDF is also a real submission artefact and should be committed alongside the .docx.

7. **Don't touch the applications tracker.** `/tailor-cover-letter` produces drafting artefacts; the tracker move from `spotted.md` to `in-progress.md` happens later when Luke separately reports the application as submitted (per [[project-applications-tracker]]). Don't ask "is this for submission this session?" — that's not a question this skill needs to answer.
8. **Commit**: single bundled commit covering all changed files in this session — the new/updated `notes.md`, the `cover-letter.md` letter source, the rendered `Luke Blaney - Cover Letter.docx`, and `Luke Blaney - Cover Letter.pdf` if `--pdf` was used. Commit message can name the company freely — this is a private repo per `feedback_cv_application_privacy.md`. Suggested format:
   > "Add {Company} {Role} cover letter"
   >
   > Brief body summarising the opener pattern + evidence story used + any notable stylistic decisions.
9. **Push**: `git push origin main`.

## Step 11: Report back

Tell Luke:

- **File path** of the letter source (`~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cover-letter.md`)
- **Path of the committed .docx**: `…/{role-slug}/Luke Blaney - Cover Letter.docx` — submission-ready filename, upload as-is to the ATS
- (Mention the `--pdf` flag only if Luke asked for a PDF; default is docx-only.)
- **Word count** of the final letter
- **Library blocks used** — which opener, which story, which current-focus variant
- **Upstream propagation that happened** — list each commit that landed in `lukeblaney_cv` or `~/.claude` as part of the session, with a one-line summary of why
- **Any new memory captured** during the session (banned words flagged, framing preferences confirmed, etc.) so Luke knows what's been saved for future sessions
- **Suggested submission route** — most ATSes want the .docx as an upload; for a text-area field the markdown body is pasteable as-is

If Luke needs to regenerate later (e.g. after a red-line edit), the manual path is the same script call as Step 10.6, followed by `git add` of the regenerated .docx and a commit.

## Git identity

All commits use the career-advisor GitHub App. Use the standard wrappers:

```bash
~/sandboxes/lucos_agent/git-as-agent --app career-advisor commit -m "..."
~/sandboxes/lucos_agent/gh-as-agent --app career-advisor ...
```

Commit directly to `main` on both `lukeblaney_cv` and `lukeblaney_cv_tailored` — neither has a PR workflow.

## When this skill is not the right tool

- **Luke wants to update the library itself** (add a new story, change the template, rewrite an opener pattern) — that's a normal career-advisor edit to `lukeblaney_cv/cover-letters/`, not a per-application task. Skip the JD-analysis steps.
- **Luke wants a CV variant** — use `/tailor-cv`, not this skill.
- **Luke wants analysis of a JD without producing a letter** — do Steps 1–4 and stop.
- **No JD URL or JD text is available** — ask Luke for one before starting.
- **The company already has a closed application that Luke isn't reopening** — confirm with Luke whether to draft a new letter or just update the company-notes outcome field.
