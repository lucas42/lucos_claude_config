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

## Step 1: Defer the artefact-set question to after the form probe

This skill **always generates a tailored CV**. What ELSE it produces (a `.docx` cover letter, plain-text textarea answers for one or more custom questions, an Additional Information answer, or nothing else) depends on the shape of the actual application form — not on a default-cover-letter assumption.

**Don't ask the CV-vs-CV-plus-letter question up front.** That question is now driven by Step 3.5 (form probe) and answered with the actual form fields in front of Luke. Asking up front guesses at the form and frequently produces over-rendered artefacts (e.g. a `.docx` cover letter for a form that only has a textarea).

Sub-steps marked `[LETTER]` in this skill refer to whichever letter-shaped artefacts get produced after Step 3.5 — they may be a `.docx` letter, a plain-text textarea, a per-question free-text answer, or nothing. Letter-specific consultation (library blocks, voice rules, standalone-ness checks, year-claims) applies to all of them; only the rendering and file-naming differ.

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
- **Pinpoint** (custom careers domain, e.g. `careers.{company}.{tld}`, path `/postings/{uuid}`): `curl -s "https://careers.{company}.{tld}/postings.json"` returns all live postings as JSON (`data[]`) with full `description` HTML, `compensation`, `deadline_at`, and `job.department`/`division`. Match the target by its UUID appearing in the entry's `url`/`path`. The per-posting `.json` returns 406; a fuller JD PDF is often linked inside the `description` HTML (grep for `href`).
- **Workday / iCIMS / Taleo / generic**: try WebFetch first. If thin content comes back, ask Luke to paste the JD text.

Extract:
- Role title and seniority level
- Company name, team or department, location, employment type
- Full JD text (responsibilities + requirements + nice-to-haves + culture blurb)
- Salary / compensation if disclosed

## Step 3.5: Probe the application form

Before joint analysis, fetch the **application form structure** so the artefact set is driven by what the form actually accepts. The same API endpoints used in Step 3 expose form fields; the cost of probing them is one extra request.

**Per-ATS endpoints:**

- **Greenhouse**: append `?questions=true` to the boards-api URL. The response includes a `questions` array; each entry has `label`, `description` (HTML — often contains word-count or format guidance), `required`, and `fields[0].type` (e.g. `input_file`, `textarea`, `input_text`, `multi_value_single_select`). Example: `curl -s "https://boards-api.greenhouse.io/v1/boards/{org}/jobs/{id}?questions=true"`.
- **Lever**: the posting JSON returned in Step 3 includes form metadata. For deeper detail, fetch `https://jobs.lever.co/{company}/{id}/apply` HTML and grep for custom field blocks (`data-qa="custom-question"` markers).
- **Ashby**: the public posting-api response includes an `applicationFormDefinition` field per job listing the form's required / optional inputs and their types — but this field can be `null` on some boards (observed 2026-05-27).  When null, fall back to asking Luke to inspect the form manually, same as the Workday/iCIMS/Taleo path below.
- **Pinpoint**: the form's file-upload and custom-question fields are JS-rendered — NOT in the static `/postings/{uuid}/applications/new` HTML (which only carries name/email/phone/LinkedIn, an optional "Personal Summary" textarea, and DEI fields). Don't infer the uploads or custom questions from the static HTML; ask Luke to confirm what the form shows (same as the Workday/iCIMS/Taleo path).
- **Workday / iCIMS / Taleo / generic**: no public API. Ask Luke to paste a screenshot of the application form or list the fields by name. Don't guess.

**Categorise each field** into one of these submission shapes:

| Shape | Example field labels | What to produce |
|---|---|---|
| CV file upload | "Resume/CV", "CV", "Resume" (`input_file`) | `Luke Blaney - CV.docx` (always — this skill always produces a CV) |
| Cover letter file upload | "Cover Letter" (`input_file`) | `Luke Blaney - Cover Letter.docx` via the standard 4-paragraph template |
| Cover letter textarea | "Cover Letter" (`textarea`, no file alternative) | Cover letter body as **plain markdown** for the textarea; **no `.docx` render** |
| Custom free-text question | "Why X?", "What interests you about this role?", "Tell us about a security project you led" (`textarea` with prompt) | A **short standalone answer per question**, sized to the description's word-count guidance |
| Optional Additional Information | "Additional Information", "Anything else you'd like to share" (`textarea`) | Optional; offer to draft if the rest of the form doesn't carry the cover-letter material |
| Non-content fields | Visa, location, start-date, demographic (`input_text`, `multi_value_single_select`) | Out of scope for `/tailor`; Luke completes himself |

**Report findings to Luke** as a table of the content-bearing fields with their types, required-flags, word-count guidance (from the description), and what you'd produce. Get sign-off on the artefact set before continuing.

**Critical: when multiple content-bearing textareas exist, plan a clean content split.** The same material must not be duplicated across fields. Default split when both a "Why X?" textarea and an "Additional Information" textarea exist:

- **"Why X?" answer** = why-this-company + company-mission alignment + company-specific evidence (the cover-letter paras 3 + relevant pieces of 4).
- **"Additional Information" answer** = role-fit framing + concrete CV evidence + brief career-break note (the cover-letter paras 1 + 2 + close).

Adapt the split to the actual questions on the form. Whatever split is chosen, name the disjoint content split in the Step 3.5 sign-off message so Luke can spot duplication risk before drafting.

**Save the form-probe findings** to `orgs/{company-slug}/notes.md` under a `## Application form` section, including the artefact-set decision. This persists across future invocations and informs follow-up applications to the same company.

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
3. **Skills section** — target **~5 categories** (not 8) of grouped, comma-separated keywords, JD-tuned. Candidate categories: Engineering Leadership, Architecture & Distributed Systems, Programming & Systems, Engineering Practice, Cloud & Platform, Cyber Security, Data & Platform, Generative AI. Pick ~5 by consolidating adjacent themes for the specific JD; reorder so the most JD-relevant category leads. **Layout**: structure as a single paragraph with hard line breaks between categories (`\` at end of each line except the last), not as separate paragraphs — this avoids inter-paragraph spacing bloat. See [[cv-skills-section]] for the rule and the markdown template.
4. **Bullet reframes** — bullets to reorder, expand, or rephrase. Pay particular attention to bullets that overlap with the letter's evidence story: if the letter centres on a specific story, the corresponding CV bullets should match its emphasis.

Get sign-off on each block before continuing.

## Step 10: Propose letter-shaped content `[LETTER]`

The shape of this step depends on the artefact set chosen in Step 3.5. Draft each piece in a single pass, applying the joint positioning decisions from Step 8 and consistent with the CV Summary signed off in Step 9. Don't show Luke until the assembled output is ready — he prefers reviewing complete drafts rather than paragraph-by-paragraph.

### Variant A: Full 4-paragraph cover letter (file upload OR letter-shaped textarea)

1. **Paragraph 1 (Anchor, 40–60 words)** — based on the chosen opener pattern. Must stand alone per `feedback_cover_letter_standalone.md`.
2. **Paragraph 2 (Evidence, 80–120 words)** — pull the chosen story from `evidence-stories.md`; adapt to the JD's specific signals. Don't quote verbatim — treat the library as a starting point.
3. **Paragraph 3 (Why this role / company, 60–100 words)** — bespoke. Default to writing about why the *role-shape* is interesting, not the company's mission, unless Luke surfaced specific knowledge of the company in Step 4 or Step 7.
4. **Paragraph 4 (Current focus + close, 80–130 words)** — start with the chosen current-focus variant from `current-focus.md`. Embed the career-break aside per Step 8 (single phrase, not its own sentence by default). End with the chosen close.

For **file upload**: include salutation, paragraphs 1–4, close + sign-off. Render to `.docx` (see Step 13).
For **letter-shaped textarea** (no file upload alternative): same structure but **omit salutation, sign-off, and first-line NBSP indent** — textareas don't render typographic conventions, and recipients see paragraphs directly. No `.docx` render.

### Variant B: Per-question textarea answers

Draft a separate standalone answer for each content-bearing question on the form (the split decided in Step 3.5). Each answer is self-contained — it doesn't reference the other answers or the CV. Apply the same library blocks selectively:

- **"Why X?" answers (company-focused)** — typically 200–400 words depending on the field's guidance. Lead with the mission/alignment angle (the cover letter's paragraph 3 content), expand with current-focus material (paragraph 4) where it bridges to the company. Open with a sentence that engages with the question directly; don't open with "I'm an X who..." (same rule as cover-letter para 1).
- **"What interests you about this role?" answers (role-focused)** — typically 150–300 words. Lead with the role-shape framing (the cover-letter paragraph 1 opener), bring in one evidence story (paragraph 2 content). No salutation, no sign-off.
- **"Tell us about a project / challenge / experience..." answers (evidence-focused)** — typically 200–400 words. STAR / CAR-shaped concrete story; pick the most JD-relevant story from `evidence-stories.md`.
- **"Additional Information" answers (optional, role-fit-focused when company-content lives elsewhere)** — typically 150–300 words. Covers whatever content the other textareas don't carry — usually role-fit framing + concrete evidence + brief career-break note. Skip entirely if the rest of the form already covers everything worth saying.

**Disjoint content** is enforced from the split decided in Step 3.5. Before showing Luke any draft, re-check that the same facts / framings / library blocks aren't appearing in multiple answers. Where they overlap by accident, pick which answer owns each piece and trim the duplicate.

All variant-B answers are plain markdown — no salutation, no sign-off, no first-line indent, no `.docx` render. They get pasted directly into form textareas.

### Common to all variants

- Library blocks (`openers.md`, `evidence-stories.md`, `current-focus.md`, `career-break-aside.md`, `closes.md`) apply to whichever variant is being drafted; pick the same ones the joint positioning decisions in Step 8 selected.
- Em-dash rule (max 1 per document) applies to each drafted artefact independently — a "Why X?" answer and an "Additional Information" answer are separate documents, each gets up to 1 em-dash.
- Banned-words and dialect rules apply to all variants.
- Year-claims overlap rule applies *within each artefact independently*, then *across the artefact set together* — when multiple artefacts will be read together by the same recipient (e.g. all textareas in one application form), the year-claims total across them combined should still respect the ~15-year ceiling.

## Step 11: Self-checks

Before showing Luke the final assembled output, run the checks below. Fix any failure before showing.

**CV**:
- **Page count**: hard limit 3 pages **in the recipient's Word / Pages view**, target ~2. Verified against the **.docx** (via LibreOffice round-trip — see Step 14), NOT the LaTeX-PDF. The headless round-trip under-counts Word/Pages by up to ~1 page, so apply the margin in Step 14: headless ≤ 2 ships without asking; headless = 3 is NOT an auto-pass — check the page-3 fill (a near-full page 3 is likely 4 in Word, so trim toward 2); headless ≥ 4 is unsubmittable. See [[cv-page-count]].
- ATS metrics (from Step 14 verification): `cid` / `ligs` / `hyphens` all 0 (non-negotiable)
- JD top keywords: all present in the rendered text

**Letter-shaped artefact(s)** `[LETTER]` — applied to each artefact independently:
- **Banned words scan**: "leverage", "AI Native", "synergies", "step change", "unlock value", "transformational", "genuinely motivated", "deeply passionate". Any hit → revise.
- **Standalone-ness check**: each sentence parseable without the CV.
- **Em-dash count**: at most 1 per artefact. A "Why X?" answer and an "Additional Information" answer are separate documents, each gets up to 1.
- **Word count**:
  - Variant A cover letter: target 250–350; 400 ceiling for senior roles with substantive technical content.
  - Variant B per-question textarea: target whatever the form's description suggests (often 200–400 for "Why X?", 150–300 for shorter prompts). When no guidance is given, default to 200–300.
- **Overlap-years check**: sum of "[N] years of [domain]" claims ≤ ~15 years, *within each artefact independently AND across the whole artefact set together* (a recipient reads them all together in one form submission).
- **Role-duration check**: any "[N] years" or "[X] months" claim tied to a NAMED specific role (e.g. "For two years I was architect on X") — cross-check against the date range for that role in cv-extended.md before showing Luke.  Don't round up.  Different failure mode from overlap-years; see [[role-duration-precision]].
- **Dialect check**: no Americanisms (`-ize`, "organization", "color", "behavior", "math", "specialty").
- **Variant A only**: salutation present (file-upload only); close + sign-off present (file-upload only). Skip if `form-shape: textarea`.
- **Variant B (and Variant A textarea form-shape)**: no salutation, no sign-off. Each answer opens by engaging the question directly. **URLs include the scheme** (`https://example.com/path`, not `example.com/path`) — see [[textarea-url-scheme]]. Bare-host URLs only work in rendered formats where the display text and underlying link can differ.

**Cross-artefact consistency** (when more than one letter-shaped artefact is produced, OR alongside the CV):
- Level-positioning in CV Summary and all letter-shaped artefacts must match (e.g. all IC-track, or all Director-track).
- Narrative tilt consistent across all artefacts.
- Career-break treatment consistent: same voice in CV section and any letter-shaped artefact that mentions it (typically one mention across the whole set, not multiple).
- Current-focus framing (lucos_agent / multi-persona LLM fleet) described in the same register everywhere it appears.
- **Disjoint content**: when multiple letter-shaped artefacts go in the same submission (e.g. "Why X?" + "Additional Information"), re-verify the content split decided in Step 3.5 actually holds in the drafts. List the key facts / framings each artefact contains; flag any that appear in more than one and decide which artefact owns it.
- Year-claims totalled across the artefact set ≤ ~15 years; the CV is structured (dates listed by role) so internal consistency isn't at risk there.

## Step 12: Upstream propagation

Before committing the per-application work, scan the session for content worth propagating back so future invocations inherit it.

### Pre-flight: ensure `lukeblaney_cv` is on `main` and up to date

Before any commit to `lukeblaney_cv` (categories 4–7 below), run:

```bash
cd ~/sandboxes/lukeblaney_cv && git checkout main && git pull --ff-only origin main
```

The repo accepts non-career-advisor commits (CircleCI / Dockerfile / Docker-image work) via a PR workflow, so the local working copy can end up on a feature branch or behind `origin/main`. Checking out `main` + fast-forward-only pull prevents accidentally committing onto a stale feature branch or building on out-of-date state. The `lukeblaney_cv_tailored` repo doesn't have this issue — no PR workflow, career-advisor is the only writer.

**Privacy gate** (applies to every commit to a public repo, not just at submission sweep): per [[cv-application-privacy]], scan the diff for employer names before each individual commit to `~/.claude/agent-memory/`, `~/.claude/skills/`, `~/sandboxes/lukeblaney_cv/`, or any other public repo. Replace target-employer mentions with fictional placeholders ("Acme Corp", "Acme AI Lab", "Acme Invest" — whichever encodes the industry signal). Tool / product names that are already public information (e.g. "Claude", "Anthropic API" as a product, "GitHub", "Okta") may stay; what gets redacted is anything that signals Luke is *applying to* the named employer. The submission sweep ([[submission-memory-sweep]]) runs the same scan as a final backstop, but per-commit scanning is the primary gate — by submission time, mid-session leaks are already public.

For each piece of new content surfaced:

1. **New defensible skill / language / methodology Luke confirmed**
   → append to `~/.claude/agent-memory/career-advisor/user_skills_inventory.md`
   → default-save with a one-line notification
   → apply the privacy gate before the auto-commit fires

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
   → its own commit before the per-application work so future `/tailor` invocations inherit it

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
- `orgs/{company-slug}/notes.md` — company-level context + per-role sections + per-role `## Application form` block
- `orgs/{company-slug}/{role-slug}/cv.md` — CV variant
- `[LETTER]` `orgs/{company-slug}/{role-slug}/cover-letter.md` — only when the form has a cover-letter file upload OR a single letter-shaped textarea (Variant A in Step 10)
- `[LETTER]` `orgs/{company-slug}/{role-slug}/why-{company-slug}.md` — answer to a "Why X?" textarea (Variant B). Plain markdown, no YAML salutation/sign-off.
- `[LETTER]` `orgs/{company-slug}/{role-slug}/additional-information.md` — answer to an "Additional Information" textarea (Variant B). Plain markdown.
- `[LETTER]` `orgs/{company-slug}/{role-slug}/{question-slug}.md` — answer to any other custom-question textarea (Variant B). Slug from the question label (e.g. `what-interests-you.md`, `tell-us-about-a-project.md`).

Slug rules: lowercase-kebab of company name; lowercase-kebab of role title; lowercase-kebab of the question label (shortened sensibly) for per-question textarea files.

### Write the CV variant

Start from `~/sandboxes/lukeblaney_cv/cv-extended.md`. Apply:

1. Add Summary section between contact block and Employment
2. Add Career Break & Current Focus section (before Skills) — **wrap the date line (`March 2025 – present`) in `::: {custom-style="EmployerDate"} ... :::` so it picks up the italic, tight-spacing paragraph style. Existing Employment / Education subtitle lines are already wrapped in cv-extended.md; the Career Break section needs the wrapping applied during variant creation because cv-extended.md doesn't have that section.**
3. Add Skills section with JD-tuned grouped keywords
4. Apply role-specific bullet reframes per Step 9

The `EmployerDate` paragraph style sits in the docx reference template; a matching `employerdate` environment in the LaTeX header (plus a Lua filter that translates the divs) gives the PDF the same treatment. Anywhere a date subtitle appears under a heading, wrap it in the custom-style div. Don't add `*...*` markdown italic — the style supplies the italic itself.

Apply the standard cuts (variants land at 3 pages by default):

1. **Collapse adjacent Principal Engineer entries** — cv-extended.md has three PE entries covering Feb 2018 – Mar 2022. Combine into a single entry titled `## Principal Engineer - Reliability Engineering, Cyber Security, Observability & Edge Delivery` with dates `Financial Times: February 2018 - March 2022`. Keep 5–7 best bullets across the three.
2. **Compress oldest roles to Earlier Career** — roles 10+ years old become one-liners (Labs Developer at FT Labs, Web Developer at Assanka). Format: `- Company - **Role**: dates`.
3. **Trim Talks & Panels to top 4** — keep JD-relevant entries.
4. **Drop reflective closing paragraphs** in non-recent role entries.
5. **Drop Education's A-levels and GCSEs**.
6. **Drop `# Earlier Career` (pre-Assanka) and `# Positions of Responsibility`** unless individual entries are directly relevant to the target employer/industry (per `feedback_cv_variant_content_rule.md`).

### `[LETTER]` Write the letter-shaped artefact(s)

The shape depends on Variant A vs Variant B from Step 10.

**Variant A: 4-paragraph cover letter** (`cover-letter.md`)

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
form-shape: file-upload   # or: textarea
---

Dear {salutation},

{body paragraphs 1–4}

Kind Regards,

Luke Blaney
```

If `form-shape: textarea`: omit salutation, sign-off, and first-line NBSP indent from the body — textareas don't render typographic conventions. The YAML metadata still goes in for record-keeping.

**Variant B: per-question textarea answer(s)** (`why-{company-slug}.md` / `additional-information.md` / `{question-slug}.md`)

YAML frontmatter records which question this answers and the library-block sources; body is plain markdown, no salutation or sign-off.

```markdown
---
question: {exact question label from form}
form-field-type: textarea
required: {true|false}
word-target: {200-400 from form description, or sensible default}
drafted: {YYYY-MM-DD}
library-source: lucas42/lukeblaney_cv/cover-letters/
content-from-paragraph: {3 | 4 | 1+2 | custom}
---

{answer body}
```

### Update or create notes.md

- If `notes.md` exists: append a new role section under `## Roles applied for`. Don't duplicate company-level notes.
- If not: create with company-level notes (industry, ATS, public job-board URL, API endpoint if useful) + first role section.
- Include a `## Application form` block under the role section listing the form fields, their types, and the content-split decision from Step 3.5.

### Render

```bash
# CV: always rendered to .docx
~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md

# Cover letter for file-upload form fields: render to .docx
~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cover-letter.md

# Cover letter for textarea form fields, and per-question textarea answers: DO NOT render to .docx.
# The markdown source IS the submission artefact (Luke copy-pastes into the form).
```

The script renders the `.docx` only by default — that's the canonical submission artefact for ATSes with a file-upload field. Pass `--pdf` (before the markdown path) only when an application or recipient specifically asks for a PDF (e.g. a recruiter wants to share the file directly rather than receive an upload). Any PDF produced this way IS a deliberate submission artefact and should be committed alongside the .docx — see the Outputs list below.

**Don't render a `.docx`** for cover letters whose form field is a textarea, or for per-question textarea answers. Doing so produces a misleading artefact (Luke would be submitting the markdown text, not a `.docx` upload). The markdown file is the canonical source-and-submission for textarea content.

Outputs (in the role-slug directory):
- `Luke Blaney - CV.docx` (always — committed, ATS-ready submission name)
- `[LETTER]` `Luke Blaney - Cover Letter.docx` (only when form has a CL file upload — committed)
- `[LETTER]` `cover-letter.md` / `why-{company-slug}.md` / `additional-information.md` / `{question-slug}.md` (plain markdown for textarea fields — committed)
- With `--pdf` on the CV: `Luke Blaney - CV.pdf` (committed alongside the .docx — see commit list below)
- With `--pdf` on the cover letter: `Luke Blaney - Cover Letter.pdf` (committed alongside)

### Commit

**Don't touch the applications tracker.** `/tailor` produces drafting artefacts; the tracker move from `spotted.md` to `in-progress.md` happens later when Luke separately reports the application as submitted (per [[project-applications-tracker]]). The submission sweep handles tracker + memory updates together. Don't ask "are we applying this session?" — that's not a question this skill needs to answer.

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

Run the Python verification on the rendered PDF. The verification uses `pdfminer.six` in a dedicated venv at `/tmp/pdfvenv`. The bootstrap line below is idempotent — it only does the install on first use and is a no-op afterwards:

```bash
# Bootstrap pdfvenv if not present
[ -x /tmp/pdfvenv/bin/python3 ] || (python3 -m venv /tmp/pdfvenv && /tmp/pdfvenv/bin/pip install -q pdfminer.six)

# Round-trip .docx → PDF via LibreOffice (in docker) — the .docx is what gets submitted, so its layout
# (Word/LibreOffice's, not LaTeX's) is what determines true page count for ATS purposes.
DIR="/home/lucas.linux/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}"
docker run --rm -v "$DIR:/data" --entrypoint /bin/bash linuxserver/libreoffice:latest \
  -c "libreoffice --headless --convert-to pdf --outdir /tmp '/data/Luke Blaney - CV.docx' >/dev/null 2>&1 && cp '/tmp/Luke Blaney - CV.pdf' '/data/Luke Blaney - CV (from docx).pdf'"

/tmp/pdfvenv/bin/python3 <<'EOF'
from pdfminer.pdfparser import PDFParser
from pdfminer.pdfdocument import PDFDocument
from pdfminer.pdfpage import PDFPage
from pdfminer.high_level import extract_text
import re

# Use the LibreOffice-rendered PDF for page count + content checks — this reflects the actual .docx layout.
path = '/home/lucas.linux/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/Luke Blaney - CV (from docx).pdf'
with open(path,'rb') as f:
    pages = list(PDFPage.create_pages(PDFDocument(PDFParser(f))))
text = extract_text(path)
print(f'DOCX pages: {len(pages)}, words: {len(text.split())}')
print(f'cid={len(re.findall(r"(cid:\\d+)", text))}  '
      f'ligs={sum(text.count(c) for c in [chr(0xFB01),chr(0xFB02),chr(0xFB00)])}  '
      f'hyphens={len(re.findall(r"\\w-\\n\\w", text))}')

jd_keywords = [...]  # substitute top keywords from Step 4
lower = text.lower()
missing = [k for k in jd_keywords if k not in lower]
print(f'JD keywords missing: {missing if missing else "none"}')
EOF
```

The `Luke Blaney - CV (from docx).pdf` file is a verification artefact, not a deliverable — `lukeblaney_cv_tailored`'s top-level `.gitignore` has a specific `*(from docx).pdf` pattern that keeps it out of `git add`. Other PDFs (the `Luke Blaney - CV.pdf` from `render-tailored.sh --pdf`) are NOT gitignored and should be committed alongside the .docx when present.

Targets:
- **DOCX pages** (headless LibreOffice round-trip): the headless count **under-counts the recipient's Word / Pages view by up to ~1 page** (confirmed twice — Apple Pages 2026-05-23, Word 2026-06-01). Apply that margin:
  - **headless ≤ 2 → ship without asking.** 2 is the target and safe against the margin.
  - **headless = 3 → do NOT auto-pass.** Inspect the page-3 fill. A *sparse* page 3 (a stray Education line, one or two Talks) is genuinely 3 in Word — acceptable. A *near-full / jam-packed* page 3 will almost certainly be 4 in Word — run surgical line-wrap-orphan trimming + standard cuts to reach ≤ 2; only ship at 3 if the content genuinely can't be cut, and then flag to Luke that it may render as 4 pages in his viewer.
  - **headless ≥ 4 → unsubmittable.** Cut and re-render before showing Luke. Standard cuts in priority order: drop Publications, drop Talks & Panels (or trim to 2 entries), trim Architect-Content bullets to 4, collapse Platform Architect to intro + 2 bullets, tighten Career Break, combine Director + Interim VP entries if a single intro line works.
- **cid / ligs / hyphens**: all 0 (non-negotiable — if any are >0 the geometry/header is broken).
- **JD keywords**: all top-tier keywords present.

(The LaTeX-PDF (`Luke Blaney - CV.pdf`) is only produced when `render-tailored.sh --pdf` is invoked. When invoked deliberately — e.g. a recruiter has asked for a PDF for direct share — that PDF IS a real submission artefact and should be committed alongside the .docx. The page count check still runs against the LibreOffice round-trip of the .docx, not the LaTeX-PDF, because the .docx is the format under the ATS-page-count constraint.)

**Cover-letter `.docx` verification** (Variant A file-upload only): same round-trip-via-LibreOffice procedure on `Luke Blaney - Cover Letter.docx`. Targets: 1 page (hard limit 2), cid/ligs both 0, em-dash count ≤ 1 in extracted text.

**Textarea-content verification** (Variant A textarea form-shape, or any Variant B answer): no LibreOffice round-trip needed (no `.docx`). Word count on the markdown source against the form's target; em-dash count via grep against U+2014; banned-words grep; standalone-ness re-read. Disjoint-content cross-check across multiple textarea answers per Step 11.

## Step 15: Report back

Tell Luke:

**CV artefacts**:
- Source path: `~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md`
- ATS upload (.docx): `…/Luke Blaney - CV.docx`
- Page count, word count, ATS metrics, JD keyword check result
- (Mention the `--pdf` flag only if Luke asked for a PDF; default is docx-only.)

**`[LETTER]` Letter-shaped artefact(s)** — one entry per artefact produced:

For Variant A cover letter (file upload):
- Source path: `…/cover-letter.md`
- ATS upload (.docx): `…/Luke Blaney - Cover Letter.docx`
- Word count, library blocks used (opener, story, current-focus variant)

For Variant A cover letter (textarea form-shape):
- Source path: `…/cover-letter.md`
- **What to do with it**: paste the markdown body (without the YAML frontmatter) into the form's cover-letter textarea
- Word count, library blocks used

For each Variant B per-question textarea answer:
- Source path: `…/why-{company-slug}.md` / `…/additional-information.md` / `…/{question-slug}.md`
- **Which form field it answers** (verbatim label from the form)
- **What to do with it**: paste the markdown body (without the YAML frontmatter) into that textarea
- Word count, library blocks used, content split (which paragraphs of the cover-letter template it draws from)

**Joint positioning summary** — what was decided at Step 8:
- Level-positioning
- Narrative tilt
- Year-claims framing
- Career-break treatment
- Tone register

**Upstream propagation that landed**: list each commit in `lukeblaney_cv` or `~/.claude` (with one-line summary), plus any default-saved memory changes from Step 12.

**Any new memory captured** during the session, so Luke knows what's been saved for future invocations.

**Suggested submission route**: walk Luke through the form-field-by-form-field mapping from Step 3.5. For each content-bearing field, name the artefact that fills it and the format (`.docx` upload vs paste-the-markdown-body). For non-content fields (visa, location, start date, demographic), Luke completes himself.

If Luke needs to regenerate later (e.g. after a red-line edit):

```bash
# CV (always renders to .docx):
~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cv.md

# Cover letter for file-upload forms (renders to .docx):
~/sandboxes/lukeblaney_cv/render-tailored.sh ~/sandboxes/lukeblaney_cv_tailored/orgs/{company-slug}/{role-slug}/cover-letter.md

# Textarea content (no .docx render needed — markdown source IS the submission artefact;
# just edit the .md and commit).
```

…then `git add` the regenerated `.docx` (or the edited `.md`) and commit.

## Git identity

All commits use the career-advisor GitHub App. Use the standard wrappers:

```bash
~/sandboxes/lucos_agent/git-as-agent --app career-advisor commit -m "..."
~/sandboxes/lucos_agent/gh-as-agent --app career-advisor ...
```

Commit directly to `main` on both `lukeblaney_cv` and `lukeblaney_cv_tailored` — neither has a PR/review workflow.

## When this skill is not the right tool

- **Luke wants only a CV, no letter or textareas** — handled natively: Step 3.5 produces a CV-only artefact set if the form has no letter file upload, no letter textarea, and no custom content questions. If Luke explicitly wants CV-only regardless of the form, skip the `[LETTER]` sub-steps and produce just the CV.
- **Luke wants only a letter, no CV** — this skill defaults to always producing a CV, but if Luke explicitly asks for letter-only, skip the CV-writing parts of Steps 9, 13, and 14 and run only the `[LETTER]` sub-steps. (Rare — most forms want a CV; don't volunteer letter-only.)
- **Luke wants to update the cover-letter library or `cv-extended.md` itself** (add a new story, change the template, rewrite an opener) — that's a normal career-advisor edit, not a per-application task. Skip the JD-analysis steps.
- **Luke wants analysis of a JD without producing artefacts** — do Steps 1–6 and stop; don't write any files.
- **No JD URL or JD text is available** — ask Luke for one before starting.
- **The company has a closed application that Luke isn't reopening** — confirm with Luke whether to draft fresh material or just update the company-notes outcome field.

## Source-of-truth files

This skill is self-contained — it carries all the CV and cover-letter logic itself (it's the sole tailoring skill; the older single-purpose `/tailor-cv` and `/tailor-cover-letter` skills were removed 2026-06-03 as Luke used `/tailor` for everything).

Most durable logic lives in shared files, not in this skill text — update those and every future invocation inherits the change:
- Memory files: `user_skills_inventory.md`, `user_role_framing.md`, the `feedback_*` standing rules.
- The cover-letter library: `~/sandboxes/lukeblaney_cv/cover-letters/blocks/`.
- The CV source-of-truth: `~/sandboxes/lukeblaney_cv/cv-extended.md`.
