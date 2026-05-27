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

- When populating a Source field, only write what is directly known. If the JD URL has a tracking parameter that's reliably channel-attributing (e.g. `gh_src=LinkedIn`, `iisn=LinkedIn`, `lever-source=LinkedinPosting`), it's reasonable to mark "LinkedIn (inferred from JD URL tracking)" — but mark the inference.
- Generic Greenhouse tracking codes (e.g. `gh_src=34ewj2`) are opaque hashes that do not identify a channel — do not infer LinkedIn or any other source from them.
- If the source isn't recorded in `orgs/{slug}/notes.md` and can't be inferred, write `TODO — confirm with Luke` and ask him in the next session. Never fabricate.
- When migrating data from per-org notes into the tracker, audit any Source field I populate from the ATS field — they should never be the same.

Related: [[project-applications-tracker]].
