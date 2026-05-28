---
name: reference-linkedin-job-tracker-export
description: How to extract Luke's LinkedIn job-tracker buckets (Saved/Applied/Archived) and what fields the SDUI payload actually contains
metadata:
  type: reference
---

LinkedIn's job tracker (`linkedin.com/my-items/saved-jobs` or `linkedin.com/flagship-web/jobs-tracker/?stage=X`) is a Server-Driven UI (SDUI) app. Bucket data is fetched via POST to `https://www.linkedin.com/flagship-web/jobs-tracker/?stage={saved|applied|archived|clicked_apply|draft|interview}`. **One request per tab returns the entire bucket** (no real pagination from the API's perspective — pagination in the UI is client-side over the full response).

## Export workflow (validated 2026-05-28)

Browser-console snippet that auto-downloads each bucket as the user clicks tabs:

```js
(() => {
  const origFetch = window.fetch;
  window.fetch = async function(...args) {
    const url = typeof args[0] === 'string' ? args[0] : (args[0]?.url || '');
    const r = await origFetch.apply(this, args);
    if (url.includes('/flagship-web/jobs-tracker/')) {
      try {
        const text = await r.clone().text();
        const stage = (url.match(/stage=([^&]+)/) || [, 'unknown'])[1];
        const blob = new Blob([text], { type: 'text/plain' });
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = `linkedin-${stage}-${new Date().toISOString().slice(0,10)}.txt`;
        document.body.appendChild(a); a.click(); a.remove();
        console.log(`⬇ ${a.download} (${text.length} bytes, ${(text.match(/"jobId":"\d+"/g)||[]).length} jobId hits)`);
      } catch (e) {}
    }
    return r;
  };
  console.log('Armed. Click each tracker tab to download.');
})();
```

User then clicks each tab (Saved → Applied → Archived). If already sitting on a tab, click away and back to force a fresh fetch. One file per tab.

**Caveat — pagination produces multiple downloads per tab.** The UI does fetch fresh page-loads when the user pages through results, so a tab with many entries produces N files (one per page-load triggered). Each file contains 10 jobs (the current page-size). Run the dedupe across all files for that stage to get the full set.

## Per-job fields in the SDUI payload

For each job, the `requestedArguments.payload` block holds:

- `jobId` (canonical LinkedIn posting ID — e.g. `4410470443`)
- `jobTitle`
- `companyName` (with `isVerified` boolean)
- `companyLogoUrl` (base64-encoded URN — opaque)
- `locationPrimary` (e.g. "London Area, United Kingdom")
- `workplaceTypeName` (Hybrid / Remote / On-site — sometimes blank)
- `isOnsite` (boolean — derived)
- `listedAt` / `originallyListedAt` (epoch ms — LinkedIn posting time, not when user saved/applied)
- `currentStageKey` (always matches the bucket — "Saved" / "Applied" / "Archived")
- `existingNote` (user-typed note — empty for almost everything Luke has)

Canonical LinkedIn URL: `https://www.linkedin.com/jobs/view/{jobId}/`

## Per-job fields NOT present (don't bother looking)

- **No JD body / description** in the tracker payload (the public job-view page does have it in `<div class="show-more-less-html__markup">` — but requires a per-job HTTP fetch).
- **No external ATS / company-apply URL.** Only the LinkedIn URL is in the payload. The apply button on the public job page is gated behind a sign-in modal; the external redirect URL is not derivable without an authenticated session.
- **No salary / comp** structured field (sometimes embedded in JD body text).
- **No applied-at / archived-at / saved-at timestamps.** No move-history.
- **No `previousStage`, `wasApplied`, `applicationStatus`, `withdraw...`** — once a job is moved between buckets, the trail is erased. Archived bucket cannot be subdivided into "applied-then-archived" vs "saved-then-archived" from the data alone.
- **Per-bucket overlap is zero** — LinkedIn moves jobs, never duplicates. Set intersection of Saved/Applied/Archived jobIds = ∅ across all three.

## Parsing notes

- Format is React Server Components (RSC) "flight" payload. Lines `1:"$Sreact.fragment"`, `3:I["…"]`, etc. Not valid JSON top-level — parse with regex over the whole file.
- Each job appears multiple times in a single file (SSR + hydration boundary). Deduplicate by `jobId`.
- Top-level tab chips: `value":["Saved · 40"]`, `["Applied · 64"]`, etc — useful sanity check.
- Internal state keys like `opportunity_tracker_total_pages_applied = 7` confirm UI page counts.

## What to use instead when the tracker payload isn't enough

- **Recovering applied-then-archived list**: request LinkedIn's official data export via Settings → Privacy → "Get a copy of your data" → "Job Applications". CSV arrives by email within hours, contains historical apply log with timestamps independent of current bucket.
- **Gmail sweep**: search `"thank you for applying" OR "application has been received"` between dates of interest.
- **JD body / salary for a specific job**: fetch `https://www.linkedin.com/jobs/view/{jobId}/` (public, no auth, ~300KB HTML); extract `<div class="show-more-less-html__markup">` content. Polite-rate-limit (≥2s between requests).
