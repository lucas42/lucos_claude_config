---
name: user-role-framing
description: How Luke prefers to be positioned in CV variants — level-positioning narratives, voice preferences, manager-vs-IC tilts. Check before drafting Summary paragraphs.
metadata:
  type: user
---

How to frame Luke's career experience when tailoring CVs to specific JDs. Captured during the 2026-05-19 / 2026-05-20 sessions.

## Director title (Cyber Security Director, FT, Feb 2023 – Mar 2025)

The "Director" title is Luke's most recent role, but his reports were **senior engineers acting as tech and team leads** — not formal Engineering Managers or other titled people-managers.

When the JD asks for "manager of managers" or formal EM-management experience:

- **Honest framing**: "leading the function through senior tech and team leads"
- **Don't claim**: managing formal Engineering Managers, multi-layer reporting hierarchy
- **Can claim**: director-level scope, line-management of a mixed-discipline team (~12 people: engineers, risk analysts, IT governance), multi-team responsibility, mentorship

## Don't overclaim regulatory experience from FT

The UK media industry is laughably under-regulated. Stated 2026-05-21 during a fintech Staff IC consultation (Acme Invest). Despite the FT's profile, Luke's tenure there did **not** involve operating under heavy regulatory burden in the way fintech / banking / pensions / healthcare roles do.

**What's defensibly shared between FT and most other industries**: high-traffic public-facing platforms, reliability under load spikes (elections, budgets, market events), public-target organisations (nation-state actors), mission-critical systems, large-scale technical migrations.

**What's not defensible without qualification**: claims about operating under significant regulatory constraints. The FT had GDPR like everyone else, but no MiFID, no FCA capital adequacy, no AML/KYC, no SOX-equivalent, no PCI-DSS at scale, etc. Even the cyber-security work — although Luke was Director — wasn't compliance-led in the regulated-industry sense.

**How to apply:**

- For fintech / banking / pensions / regulated-industry JDs, lead with reliability + scale + cyber-security-craft, **not** regulatory experience.
- Honest framing: "fintech is a domain I haven't worked in before, but the broader pattern of [reliability / scale / public-target] is familiar territory."
- If a JD specifically asks for regulatory experience, follow the existing pattern from the regulated-pensions letter: honest gap note + adjacent evidence (CyberEssentials, PCI-DSS in the SSO context, etc.) — don't dress up the gap.

Related: [[user-cover-letter-patterns]], [[luke-voice]].

## Architect role family was phased out — architecture absorbed into PE remit

The FT re-organised in 2017 to move architects into the same orgs as engineers (architecture stopped being a separate team). After that, the explicit Architect job titles were gradually phased out through backfilling with other titles. There isn't a single sharp date to point to — but the upshot is that **the architectural-decision-making work didn't stop; it was absorbed into the Principal Engineer remit**.

This matters for positioning because it means **architecture was a substantive part of Luke's Principal Engineer work (Feb 2018 – Mar 2022)** — a 4-year period of architectural decision-making across reliability engineering, observability, edge delivery and cyber security, in addition to the team-leadership work. Confirmed by Luke 2026-05-21.

**How to apply:**

- For Staff IC and Architect-track JDs, frame architecture as **continuous from 2016 to 2025**, not bounded to the Architect-Content role.
- Add an explicit architecture-absorption bullet to the collapsed PE entry on IC variants: "the Principal Engineer remit absorbed system-architecture responsibility alongside engineering leadership; drove architectural decisions across reliability engineering, observability, edge delivery and cyber security".
- In the Summary, "continuous architectural responsibility from 2016 to 2025" is a stronger anchor than "Principal Engineer technical direction since 2018".
- **Phrasing**: don't anchor a sharp year for the dissolution — the phasing was fuzzy ("re-org in 2017 moved architects into engineering orgs; titles then gradually phased out"). Use "as the FT phased out Architect job titles…" or "after the Architect role family was wound down…" rather than "in 2018 the FT dissolved…".

This is also a direct rebuttal to a recency objection a hiring manager might form ("the architecture work was 8+ years ago") — bringing the architecture story forward in time by 4 years inside the same documents.

## Unbackfilled Principal Engineer responsibilities (Apr 2022 – Mar 2025)

Throughout the Director and Interim VP roles, Luke retained the **unbackfilled Principal Engineer technical-direction responsibilities** for Cyber Security — providing all the technical direction the role usually requires while delegating day-to-day team management to senior engineers.

- For **IC-track variants** (Staff Engineer, Principal Engineer, etc.): pull this forward as the **first bullet** of both Director and Interim VP entries.
- For **management-track variants** (Director / Head / VP of Engineering): include as the **tail bullet** so the leadership-progression narrative still leads.
- In `cv-extended.md` itself: it sits as the final bullet of both roles.

## Career break (March 2025 – present)

Luke's preferred voice — adapted from a cover letter he uses verbatim:

> *Took a career break to travel around the world. Now back in London full-time and getting hands-on experience with generative AI tools.*

Following content can describe the agentic work: multi-persona LLM agent fleet for managing a personal software estate; agents for code review, security review, SRE, architecture, UX and coordination; focus on agentic coding agents and guardrails balancing value vs risk.

**Don't**:
- Name `lucos_agent` directly — means nothing to recruiters outside Luke's projects
- Use "time travelling" phrasing — accidentally ambiguous pun
- Overhype with buzzwords like "AI Native" or "transformational change" — Luke prefers measured framing that signals his cyber-security-leader instincts around emerging-tech risk

## Cyber as platform-enablement framing (for platform-engineering JDs)

For platform-engineering JDs (where cyber isn't the primary draw but excluding the cyber years would shrink the recent-work surface), reframe the cyber experience as **a platform / enablement function with engineers as customers** rather than as a traditional cyber-security function. Confirmed by Luke 2026-05-22 for a Staff Platform Engineer role.

The cyber team at the FT genuinely worked this way — concrete evidence already in cv-extended.md that supports the reframe:

- PE-Cyber: "Led the strategy and implementation of democratisation of security data: enabling engineering teams to make better decisions around their own risks" — self-service for engineering teams
- PE-Cyber: "Advised on security related concerns across all the FT's engineering teams" — enablement, not gatekeeping
- Director: "Senior stakeholder management — acting as a bridge between business colleagues and engineers"
- PE-Cyber: SSO migration delivered across all of engineering — paved-path infrastructure

**How to apply** (platform-engineering JDs only):

- In the Summary, frame the cyber years as "platform / enablement work with engineering teams as customers" rather than as cyber leadership.
- Reorder cyber bullets to lead with the enablement / self-service ones (democratisation of security data, advisor-across-engineering-teams, company-wide SSO) and de-emphasise the strategy / governance bullets.
- Keep the cyber-security domain language present (it's a real specialism) but subordinate it to the platform-engineering narrative.
- This is a Staff/Platform-IC framing; don't deploy it for Director/Head/VP of Engineering variants where the leadership narrative is what's being sold.

Related: [[user-skills-inventory]], [[check-evidence-recency]].

## Level-positioning when the JD level doesn't match recent titles

- **Director → Staff IC** (e.g. cv-staff-engineer.md for a fintech Staff Engineer JD): frame as "deliberate technical re-focus", lead with PE-concurrent bullet, surface architecture and engineering above strategy/people-management.
- **Director → Director/Head/VP of Engineering** (e.g. cv-engineering-director.md for a platform-engineering Director JD): lean into the Director title and multi-team leadership; soften "manager of managers" per above; pull architecture experience (especially Architect - Content / publishing platform) up the page.
- **Director → Engineering Manager / Tech Lead Manager** (not yet built): expected to need a "leading through senior leads" middle-ground framing.

## How to apply

Check this file before drafting Summary paragraphs and before deciding how to reframe the Director / Interim VP bullets. If a JD raises a positioning question not addressed here, ask Luke and update this file with the answer so future variants inherit it.

Related: [[user-skills-inventory]], [[cv-variant-content-rule]], [[cv-rebuild]].
