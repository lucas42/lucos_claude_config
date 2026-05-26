---
name: cv-variant-content-rule
description: How to decide which Earlier Career / Positions of Responsibility entries to include in a CV submission variant
metadata:
  type: feedback
---

When generating a role-specific submission variant of Luke's CV from `cv-extended.md`:

**Default rule:** drop the `# Earlier Career` and `# Positions of Responsibility` sections from the submission variant. They dilute the senior-leadership pitch with content from 20+ years ago.

**Contextual exception:** if an entry in those sections is *directly relevant to the target employer or industry*, pull just that entry forward into the variant. Worked example from Luke (2026-05-19): when applying for a tech role at Sainsbury's, he mentioned the Customer Services Assistant role (May–Dec 2005) on the basis that "I'd worked on the tills before to demonstrate I had some sort of understanding of the company/industry".

**Always:** keep both sections intact in `cv-extended.md`. It's the source of truth and may be the only place where this history is recorded.

**Why:** Stated 2026-05-19. Recruiter time-to-skim is short; everything that doesn't actively support the pitch is noise. But context can rehabilitate seemingly-irrelevant entries — work-at-this-employer-before is a powerful signal in a competitive funnel.

**How to apply:** When asked to produce a `cv-{role}.md` variant, scan `# Earlier Career` / `# Positions of Responsibility` for any entry that connects to the target employer or industry. Include those; drop the rest. If unclear, ask Luke.

## Don't delete role sections that create chronological gaps

Stated 2026-05-26.  In-CV `# Employment` role entries (titled FT roles in `cv-extended.md`) should NOT be deleted from a variant just to save page space — deleting a role leaves an unexplained gap in the chronology that recruiters read as suspicious.

**Rule**: compress in place; don't delete.  If a role is too old or off-topic for the JD to justify its full footprint, compress to a minimal entry — role title + dates + one-paragraph description, no bullets — but keep the entry present so the chronology is unbroken.

**Triggered by**: 2026-05-26.  I dropped the Platform Architect - Operational Intelligence role entirely from an advisory-consultancy variant to save page space, creating an unexplained ~14-month gap between Architect - Content (Oct 2016 - Feb 2018) and Integration Engineer (Jan - Nov 2015).  Luke flagged it: "Removing the Operational Intelligence section entirely makes it look like I've unexplained gap on my CV."

**Applies to**: every titled role in cv-extended.md's `# Employment` section.  Earlier Career one-liners and Positions of Responsibility are out-of-scope for the gap rule — they're already at the "trivially droppable" end of the spectrum and pre-date the Employment chronology proper.

**Compression playbook for a role you'd otherwise drop** (tiered by age):

- **Recent or near-recent role (within last 7 years), too off-topic for full footprint**: role title + dates + one-paragraph description, no bullets. Net footprint: ~4 lines.
- **>10-year-old role, kept only as chronology / background signal**: role title + dates only, no description, no bullets. Grouped under a small `# Earlier Career` section if multiple. Net footprint: ~1 line per role.

The very-old tier exists because Luke wants pre-2014 tech job titles present (title + dates) to demonstrate his software-development background. Stated 2026-05-26: "I think it's useful have my tech-related job titles listed as far back as 2010.  Even if it's just job titles and dates for earlier roles; I think it's useful to demonstrate I've come from a software development background and I actually understand how code works."

**Don't confuse this with the `# Earlier Career` section drop rule above**, which is about cv-extended.md's pre-2010 / non-tech entries (lighting technician, work placements, retail). Those stay dropped by default. The new very-old-tier rule is about *Employment-section* roles that pre-date the senior-leadership pitch, like Labs Developer (Dec 2011 - Dec 2014) and Assanka Web Developer (Nov 2010 - Dec 2011) — these belong on the variant in title-and-dates-only form.

## Drop product / brand names from role bullets unless the JD names them

Stated 2026-05-26. In CV role bullets describing what Luke did, **drop specific product / brand names unless they are explicitly named in the job description**. Skills section is where brand-name keyword coverage lives; role bullets describe the concept and scale.

Worked example (an advisory-consultancy DevEx tailoring session):

| Before | After |
|---|---|
| "a monitoring aggregation platform spanning a mixed estate (Nagios, CloudWatch, Graphite/Grafana)" | "a monitoring aggregation platform across a mixed estate" |
| "Code Hosting (Bitbucket to GitHub, ~300 engineers), Issue Tracking (Jira, ~400 across…)" | "Code Hosting (~300 engineers), Issue Tracking (~400 across…)" |
| "~3000 users migrated to Okta on time and on budget" | "~3000 users; rescued from a stalled in-house project, delivered on time and on budget" |
| "SAST, SCA, and secret-scanning integrated into CI/CD pipelines" | "security tooling across CI/CD pipelines" |

**Keep in role bullets** (these are categories / concepts, not products):
- Concepts: observability, CI/CD, SaaS, SSO, code hosting, issue tracking, microservices, event-driven architecture
- Scale numbers: ~300 engineers, ~3000 users
- Outcomes: on time and on budget, on schedule, delivered

**Don't keep in role bullets unless JD-named**:
- Vendor / product brand names (Okta, Nagios, GitHub, Bitbucket, Jira, Grafana, Prometheus, etc.)
- Tool category names that read as "specific technologies" (SAST, SCA, secret-scanning) when a broader "security tooling" / "DevSecOps tooling" framing would land the same signal

**Where brand names DO live**: the Skills section. Skills is the keyword-density layer; role bullets are the narrative-of-impact layer. Don't duplicate.

**Triggered by**: 2026-05-26. Luke pushed back on calling out Nagios / CloudWatch / Grafana / Bitbucket / GitHub / Jira / Okta inside the PE role bullets: "I don't think calling out a bunch of specific technologies in the Principal Engineer section is useful, unless they're particular ones the JD is looking for."

**Rule of thumb**: before each role bullet, check the JD for the brand name. If it's named, keep. If not, drop.

Related: [[cv-page-count]], [[cv-rebuild]], [[cv-copy-editing-scope]], [[cv-skills-section]].
