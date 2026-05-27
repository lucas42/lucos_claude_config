---
name: project-applications-tracker
description: Central pipeline tracker at lukeblaney_cv_tailored/applications/ — three files split by lifecycle, per-org notes for detail
metadata:
  type: project
---

Central application tracker lives at `lukeblaney_cv_tailored/applications/`, created 2026-05-27 to replace the user's prior reliance on LinkedIn's job tracker.

**Structure:**

- `applications/README.md` — top-level index with the at-a-glance in-progress table and links to the three lifecycle files.
- `applications/spotted.md` — roles found but not yet applied to (triage queue).
- `applications/in-progress.md` — submitted, awaiting outcome. Grouped by funnel stage; within a stage, oldest-first.
- `applications/closed.md` — newest-first. Pre-rebuild (pre-May-2026) entries are kept under a "Pre-rebuild (historical reference)" subheading.

**Funnel stages:** Spotted → Applied → Recruiter screen → HM screen → Tech assessment → Onsite/panel → Offer → Closed (with outcome).

**Per-entry fields:** Stage, Source (channel where Luke found the role — see [[feedback-source-vs-ats]]), JD link, Applied date, Location, Comp band (if disclosed), Closing date (if known), Next action, link to `orgs/{slug}/notes.md`.

**Why this shape:**

- Three files split by lifecycle keeps each file scannable on its own and matches the mutation pattern (spotted churns, closed grows append-only, in-progress is where the action is).
- Per-org `notes.md` files at `orgs/{slug}/notes.md` already hold the rich research (ATS, company-level signals, JD form-field probes, positioning decisions, lessons-learned). The tracker doesn't duplicate this — it indexes and links to them.
- Capgemini Invent has org-level research but no specific role spotted yet, so it sits in `orgs/` without an applications-tracker entry. Future roles get a tracker entry when spotted.

**How to apply:**

- When Luke reports an application submitted: move entry from `spotted.md` to `in-progress.md` under "Applied", update README at-a-glance table.
- When Luke reports a stage change (recruiter contact, HM screen scheduled, etc.): update the stage line in `in-progress.md` and the README "Last change" date.
- When Luke reports a closure: move entry from `in-progress.md` to top of `closed.md`, remove from README at-a-glance, write outcome line.
- Luke updates almost always come through laptop sessions (he confirmed this 2026-05-27); the workflow assumes I'm in the loop for any edits. No phone-sync surface is needed.
- Honour [[feedback-cv-application-privacy]]: this directory lives in the private `lukeblaney_cv_tailored` repo. Never propagate company names into the public `lukeblaney_cv` repo, commits, or memory files outside this scope.

**Next planned action (2026-05-28):** bulk import from Luke's LinkedIn job tracker. Format / shape of the input not yet known — ask Luke when he kicks it off whether he'll export, screenshot, or paste. Each entry routes to spotted/in-progress/closed based on its LinkedIn status; default Source for these is LinkedIn unless the entry says otherwise.
