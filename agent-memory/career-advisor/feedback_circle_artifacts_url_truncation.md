---
name: feedback-circle-artifacts-url-truncation
description: Never paste raw circle-artifacts.com URLs in chat output — they get truncated where they wrap and the link breaks. Use markdown link syntax or refer to the build number + filename instead.
metadata:
  type: feedback
---

Long `circle-artifacts.com` / `output.circle-artifacts.com` URLs get **truncated by the chat UI when they wrap**, breaking the link target. When relaying CI artefact info to Luke, never paste the raw URL.

**Why:** Luke flagged this on 2026-05-20 after I'd pasted such a URL when reporting the cv.md restructure. The wrap mid-URL collapses path segments so clicking the link goes to the wrong place (or 404s).

**How to apply:**
- Prefer descriptive references: "CircleCI build #100 → `cv.pdf` artefact" rather than the full URL.
- If a URL must appear, wrap it in markdown link syntax `[descriptive text](URL)` so the visible token stays short. (Note: this only helps in markdown-rendered surfaces; in plain-text reply the URL still wraps.)
- For the rendered HTML status page on GitHub, prefer the commit-status's `target_url` referenced by its build number rather than pasted verbatim.

Applies to any long URL prone to whitespace-wrapping mid-token (signed S3 URLs, etc.), but circle-artifacts is the recurring offender.
