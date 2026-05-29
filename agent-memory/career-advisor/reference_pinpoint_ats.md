---
name: pinpoint-ats
description: How to fetch a JD and probe the application form on Pinpoint ATS (custom careers.{company} domains, /postings/{uuid} paths)
metadata:
  type: reference
---

**Pinpoint ATS** is recognisable by a custom careers subdomain (`careers.{company}.{tld}`) with posting paths like `/postings/{uuid}` and application paths `/postings/{uuid}/applications/new`. Cloudinary asset URLs reference `pinpointhq`. Used by some UK public bodies and mid-size firms.

## Fetching the JD (public, no auth)

- `curl -s "https://careers.{company}.{tld}/postings.json"` returns **all live postings** as JSON under `data[]`.
- Each entry has full `description` HTML, `key_responsibilities`/benefits HTML, `compensation` (+ min/max/currency/frequency/`compensation_visible`), `deadline_at`, `employment_type`, `workplace_type`, `location`, and `job` (with `department`, `division`, and sometimes a `structure_custom_group_one` team grouping — useful intel on where the role actually sits).
- Match the target posting by the **UUID from the URL appearing in the entry's `url` / `path`** field (the entry's own `id` is a different internal integer, not the URL UUID).
- The per-posting `.json` endpoint returns **406** (even with an Accept header) — don't use it; use `postings.json` and filter.
- A fuller **JD PDF** is often linked inside the `description` HTML ("click on this Job Description") — grep the description for `href` to find it; it usually carries the full requirements / SFIA levels / qualifications that the short web blurb omits.

## Probing the application form

- The form's **file-upload and custom-question fields are JS-rendered** — they are NOT in the static `/postings/{uuid}/applications/new` HTML. The static HTML only exposes: name, email, phone, country code, LinkedIn URL, an optional **"Personal Summary"** free-text textarea ("tell us a little more about yourself"), and DEI fields (gender, ethnicity, etc.) + consent.
- Tenant-level feature flags appear in the page JSON (e.g. `allow_cover_letters`) but these are account settings, **not** proof that this posting's form has that field.
- So: don't infer the CV-upload / cover-letter-upload / custom-question shape from the static HTML. Treat Pinpoint like the Workday/iCIMS/Taleo path — ask Luke to confirm what the form actually shows.

First encountered 2026-05-29 on a UK public-body Director application. The `/tailor`, `/tailor-cv` and `/tailor-cover-letter` skills now list Pinpoint in their Step 3 (JD fetch) and Step 3.5 (form probe) sections.

Related: [[reference-ashby-job-board-api]].
