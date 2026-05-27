---
name: ashby-job-board-api
description: Ashby's public job-board API endpoint pattern — fetches full JD content from JS-rendered Ashby pages without auth
metadata:
  type: reference
---

Ashby's careers pages at `https://jobs.ashbyhq.com/{org}/{job-id}` are client-rendered, so WebFetch on the page URL only gets the page title. To get the actual JD content:

**Endpoint**: `https://api.ashbyhq.com/posting-api/job-board/{org}`

- Public, no auth required.
- Returns all currently-open jobs for the org as JSON, including full descriptions.
- Filter by job ID (`90ad6d40-1b8e-4f41-91da-a287f17ec212` etc.) to find the specific posting.
- The per-job endpoint (`/posting-api/job-board/{org}/{job-id}`) returns 401 Unauthorized — don't use this one.
- **Form-probe gotcha**: `applicationFormDefinition` can be `null` on some Ashby boards (observed 2026-05-27 on a risk-intelligence scale-up's board).  When null, the public API gives no form-field-structure information.  Fall back to asking Luke to click "Apply" on the marketing posting and report the form fields manually — same fallback pattern as Workday/iCIMS/Taleo.  The JD description content itself is still in the response; only the form structure is missing.

**How to apply**: When Luke shares an Ashby URL of the form `https://jobs.ashbyhq.com/{org}/{job-id}`, fetch the org-level API endpoint and filter to the job ID in the prompt to WebFetch. Save raw JSON output to the private repo's company-notes file if useful for later reference.

**Other ATS platforms** (capture as discovered):
- *Greenhouse*: typically `https://boards-api.greenhouse.io/v1/boards/{org}/jobs/{job-id}` — public, no auth.
- *Lever*: typically `https://api.lever.co/v0/postings/{org}/{posting-id}` — public, no auth.
- *Teamtailor*: hosted at `careers.{org-domain}/jobs/{numeric-id}-{slug}`.  The marketing page is client-rendered, but **the apply page's HTML contains the full form structure inline** — no separate API needed.  Fetch `https://careers.{org}/jobs/{id}-{slug}/applications/new` and grep for `name="candidate[answers_attributes][N][text]"` to enumerate custom-question text fields; nearby `name="candidate[answers_attributes][N][question_id]"` hidden inputs give the question IDs.  Question prompts (the actual text shown to applicants) appear inline in the same HTML, but not always immediately adjacent — easier to extract sentences ending in `?` from the stripped-tags rendered text and match them to the questions in document order.  Field-type signals: `<textarea rows="N">` for multi-line free-text (typically 3+ rows = substantive content question; rows=1 on a `<input type="text">` = short answer like notice period / salary), `type="radio"` with `value="true"`/`value="false"` for boolean.  File-upload fields: `name="candidate[resume_remote_url]"` (CV), `name="candidate[file_remote_url]"` (Additional files — generic optional upload that can carry a cover letter).  The "candidate flavour" optional questions (Ask yourself, Fun fact, Superpower, Favourite song, etc.) are Teamtailor's standard whimsy block — drop into the form_type `custom`/`funFact`/`superpower` markers; Luke can fill in if desired but they don't need tailoring.  No `Cover Letter` file field per se — the generic `Additional files` upload is where the cover letter goes if the role warrants one.
- *Workday / iCIMS / Taleo*: usually session-bound — no simple public API for application-form structure. May need raw HTML scrape with a different user agent, or ask Luke to paste the JD content.
- *Jibe Apply (front-end for iCIMS)*: hosts at `{org}.jibeapply.com/jobs/{id}`. The page is client-rendered but the **full JD content is embedded** as `<script type="application/ld+json">` (schema.org JobPosting), extractable via `curl` + regex without auth — `directApply: true` in the JSON confirms iCIMS-direct-apply. The application form itself is session-bound (no public API). Observed 2026-05-23 on one Staff IC submission: the post-CV-profile questions were short-form / single-word answers, no free-text "Why X?" / "Tell us about a project" textareas — so a CV-only `/tailor` artefact set was sufficient. Single data-point; other iCIMS deployments may include letter-shaped textareas.
- *Large consultancy hosted on SAP SuccessFactors*: two-tier surface. Discovered 2026-05-26 against one large-consultancy posting; the pattern should apply to any consultancy whose marketing job-board sits in front of a SuccessFactors backend.
  - The marketing job-board (URL form: `{consultancy-domain}/jobs/{ref}-en_GB+sap_btp`) is **frequently empty** — the description body is just `<H2><b></b></H2>` skeleton divs. Don't trust the marketing page for JD content.
  - The `sap_btp` URL suffix is the consultancy's internal job-feed-source tag (likely SAP-backed SuccessFactors pipeline), **NOT** the SAP Business Technology Platform product. Appears on every posting regardless of role content.
  - **Job-feed API** (the consultancy fronts SuccessFactors via an Azure-hosted intermediary): `https://{consultancy-jobstream-api-host}/api/job-details/{ref}-en_GB+sap_btp` returns posting metadata as JSON. The `data.apply_job_url` field is the canonical SuccessFactors URL at `careers.{consultancy-domain}/job/.../{numeric-id}/`. The `data.description` field is often empty even when the SuccessFactors page has full content — always follow `apply_job_url` for body content. The exact intermediary host varies per consultancy; check the marketing-page HTML for a `var {prefix}_jobs_jobstream_url = "https://{host}/api"` script tag to find it.
  - **Search endpoint** for finding sibling postings: `https://{host}/api/job-search?size=50&page=1&search=<keyword>&country_code=en-gb` returns a paged list of all the consultancy's openings.
  - **Generic-title gotcha**: the `-en_GB` listings often carry a **generic feed title** (e.g. a broad professional-community name) while the parallel `-en_US` listings for the same UK posting carry the **actual specialised role title** (the discipline-specific name the SuccessFactors page shows). Cross-reference `-en_GB` to `-en_US` when the visible title looks generic.
  - **Form structure**: SuccessFactors applications are gated behind candidate registration. The form structure isn't probeable without login. Ask Luke to look at the form and report the field types directly (file upload vs textarea vs custom questions).
  - **What this lets you do**: when Luke shares a marketing-board URL with an empty body, find the jobstream API host from the marketing-page JS, hit `/job-details/{ref}` for metadata, follow `apply_job_url` to the SuccessFactors page, then WebFetch that for the real JD.

Related: [[cover-letter-rebuild]].
