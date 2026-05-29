---
name: career-break-on-parsed-timelines
description: How to fill the career-break gap when an application form auto-parses the CV into an editable experience timeline (or asks for structured employment history) — the CV's Career Break section is not parsed as a role.
metadata:
  type: user
---

When an application form **auto-parses the uploaded CV into an editable experience / employment timeline** (common on Workday, Greenhouse, Phenom-style careers sites, and many other ATSes), the CV's `# Career Break & Current Focus` section is **not** picked up as a dated role — it isn't structured like an Employment entry — so the parsed timeline shows an unexplained gap from March 2025 to present. Luke will hit this whenever an ATS builds an editable timeline from his CV.

**Fix:** add a manual timeline entry so the gap is labelled rather than silent (a labelled break reads far better than an unexplained gap):

- **Company / Employer**: `Career Break`
- **Job title**: `Career Break` — or, to surface the current technical work, `Career break — travel & independent software projects (agentic AI)`
- **Dates**: `March 2025 – Present`

**Why this shape:**
- **Don't invent an employer or a freelance title** (e.g. "Independent Software Engineer"). Luke isn't employed or contracting for clients; it's a deliberate break with personal-estate technical projects. A job-like title against a company name invites an interviewer question that the honest answer ("personal projects") then has to walk back.
- **Keep it consistent with the CV.** Match the CV's section title ("Career Break & Current Focus") and the same `March 2025 – present` dates, so the parsed timeline, the uploaded CV, and any "why this role" answer all tell the same story with no discrepancy to flag.
- **Don't overclaim in the title** — "personal / independent software projects", never a shipped product or a team using it (same restraint as the CV / current-focus library blocks).

First encountered 2026-05-29 on a retailer's custom careers site (its parser pulled the Employment entries but skipped the Career Break section).

Related: [[user-role-framing]], [[user-cover-letter-patterns]], [[cover-letter-upload-field]].
