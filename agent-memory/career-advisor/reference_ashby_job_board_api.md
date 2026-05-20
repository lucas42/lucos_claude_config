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

**How to apply**: When Luke shares an Ashby URL of the form `https://jobs.ashbyhq.com/{org}/{job-id}`, fetch the org-level API endpoint and filter to the job ID in the prompt to WebFetch. Save raw JSON output to the private repo's company-notes file if useful for later reference.

**Other ATS platforms** (capture as discovered):
- *Greenhouse*: typically `https://boards-api.greenhouse.io/v1/boards/{org}/jobs/{job-id}` — public, no auth.
- *Lever*: typically `https://api.lever.co/v0/postings/{org}/{posting-id}` — public, no auth.
- *Workday / iCIMS / Taleo*: usually session-bound — no simple public API. May need raw HTML scrape with a different user agent, or ask Luke to paste the JD content.

Related: [[cover-letter-rebuild]].
