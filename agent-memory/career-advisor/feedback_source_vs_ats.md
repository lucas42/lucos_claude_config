---
name: feedback-source-vs-ats
description: "Source" in an application tracker means the channel where Luke found the role, not the ATS that processes the application
metadata:
  type: feedback
---

**"Source" = channel where Luke found the role.** Examples: LinkedIn, direct careers page, recruiter outreach (in-house or third-party), referral, employer-event, Otta/Welcome-to-the-Jungle, conference, newsletter.

The ATS (Greenhouse, Ashby, Lever, Teamtailor, Workday, iCIMS, etc.) is where the application is **submitted**, not where the role was discovered. Do not conflate the two.

**Why:** Luke called this out 2026-05-27 when I labelled application Sources as e.g. "LinkedIn / Greenhouse" and "Greenhouse" in the new applications tracker. The ATS metadata is recorded in `orgs/{slug}/notes.md` already and serves a different purpose (probing the application form, building the right artefact set). The Source field exists for funnel analysis — which channels produce applications that progress vs. die at the recruiter screen.

**How to apply:**

- **`utm_source` is authoritative.** It's set by the platform that exposed the link (the click origin self-identifying), so a value like `utm_source=hackajob` is reliable. Use it directly as the Source, title-cased for readability. The `/spotted` skill applies this automatically; ad-hoc work should do the same.
- Other ATS-specific tracking parameters (`gh_src=LinkedIn`, `iisn=LinkedIn`, `lever-source=LinkedinPosting`) are weaker — they can be set by anyone sharing the link. If using them, mark the inference: `"LinkedIn (inferred from JD URL tracking)"`. The `/spotted` skill deliberately does NOT consult these.
- Opaque hashes (e.g. `gh_src=34ewj2`, `utm_source=q2kltu4g1us`) don't identify a channel — don't infer anything from them; treat as if no tracking exists.
- If no usable tracking exists and the source isn't recorded in `orgs/{slug}/notes.md`, write `TODO — confirm with Luke` and ask him. Never fabricate.
- When migrating data from per-org notes into the tracker, audit any Source field I populate from the ATS field — they should never be the same.

Related: [[project-applications-tracker]].
