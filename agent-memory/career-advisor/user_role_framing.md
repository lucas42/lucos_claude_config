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

### BCDR / crisis-management responsibility (Cyber Security Director)

Confirmed 2026-05-23. As Cyber Security Director, Luke was part of the **company-wide crisis management team responsible for business-continuity planning across the organisation**. This is the most senior crisis-management seat in his career and the strongest BCDR / business-continuity evidence point available.

Business continuity has been touched at several earlier points (CMDB rewrites at Platform Architect-OpsIntel; office moves at PE-Reliability Engineering as departmental rep) but the crisis-management-team membership during the Director role is the headline.

**How to apply:**

- For JDs that name **BCDR, business continuity, disaster recovery, crisis management, or compliance automation** as a responsibility (e.g. a developer-platform Deploys-team JD listing "BCDR planning, compliance automation, and security upgrades"): foreground the crisis-management-team line in the Director-Cyber bullet. The default cv-extended.md phrasing is "contributed to a new company-wide crisis management team"; sharpen for BCDR-focused JDs to "was part of the new company-wide crisis management team responsible for business-continuity planning across the organisation".
- For JDs that don't specifically name BCDR / business continuity: keep the cv-extended.md default phrasing.
- The earlier CMDB-rewrite / office-move touchpoints are not strong enough to mention on their own; subordinate to the Director-role crisis-management evidence unless a JD specifically asks about pre-crisis-management-team BC/DR experience.

## Don't overclaim regulatory experience from FT

The UK media industry is laughably under-regulated. Stated 2026-05-21 during a fintech Staff IC consultation (Acme Invest). Despite the FT's profile, Luke's tenure there did **not** involve operating under heavy regulatory burden in the way fintech / banking / pensions / healthcare roles do.

**What's defensibly shared between FT and most other industries**: high-traffic public-facing platforms, reliability under load spikes (elections, budgets, market events), public-target organisations (nation-state actors), mission-critical systems, large-scale technical migrations.

**What's not defensible without qualification**: claims about operating under significant regulatory constraints. The FT had GDPR like everyone else, but no MiFID, no FCA capital adequacy, no AML/KYC, no SOX-equivalent, no PCI-DSS at scale, etc. Even the cyber-security work — although Luke was Director — wasn't compliance-led in the regulated-industry sense.

**How to apply:**

- For fintech / banking / pensions / regulated-industry JDs, lead with reliability + scale + cyber-security-craft, **not** regulatory experience.
- Honest framing: "fintech is a domain I haven't worked in before, but the broader pattern of [reliability / scale / public-target] is familiar territory."
- If a JD specifically asks for regulatory experience, follow the existing pattern from the regulated-pensions letter: honest gap note + adjacent evidence (CyberEssentials, PCI-DSS in the SSO context, etc.) — don't dress up the gap.

Related: [[user-cover-letter-patterns]], [[luke-voice]].

## Architecture continued under the Principal Engineer remit (2018–2022)

The FT re-organised in 2017 to move architects into the same orgs as engineers, and the Architect job titles were gradually phased out. The architectural-decision-making work itself continued: it became part of the Principal Engineer remit. This means **architecture was a substantive part of Luke's Principal Engineer work (Feb 2018 – Mar 2022)** — a 4-year period of architectural decision-making across reliability engineering, observability, edge delivery and cyber security, alongside the team-leadership work. Confirmed by Luke 2026-05-21.

**Critical scope rule (revised 2026-05-22):** for any JD whose role title is **NOT** "Architect", **do not** explain the Architect-titles-phased-out story or frame Luke's transition into Principal Engineer as something that happened to him. Two reasons:

1. **It reads as "Luke was forced out of architecture by the org reshuffle"** rather than as continuous senior IC work that included architecture throughout.
2. **It explains the concept of "non-architects making architectural decisions" as if it's novel.** Any engineering org hiring a Staff / Principal / Platform Engineer with architecture expectations already operates this way; explaining it back to them reads as condescending or naive.

**How to apply (the corrected pattern):**

- **Default (non-Architect-titled JDs):** Frame architectural responsibility as **plainly part of the Principal Engineer remit**, no transition story, no absorption-from-Architect language. The PE entry's lead bullet should say something like *"The Principal Engineer remit included system-architecture responsibility alongside engineering leadership: drove architectural decisions across reliability engineering, observability tooling, edge delivery and cyber security throughout this four-year period."* In the Summary, anchor on "a decade of architecture and platform-engineering work at the Financial Times" — letting the dates carry the continuity without explanation.
- **Architect-titled JDs only (rare):** the phased-out story may be useful to explain why Luke doesn't have a recent "Architect" title despite continuous architecture work. Even here, prefer his preferred phrasing about the Content pivot ("I repositioned the architect role so that engineering squads were empowered to make their own architectural decisions"), and present the transition as something Luke drove, not something the org imposed on him.
- **The Architect-Content "proudest-accomplishment" line** ("transforming a team heavily reliant on having an architect to one where engineers felt empowered to make their own architectural decisions") is fine to keep in the Architect-Content role section itself on any variant — it's role-scoped there, not generalised. Just don't elevate that pattern to the Summary or use it as a through-line for the post-Architect years.

This rule was sharpened 2026-05-22 after I'd written a Summary for a Staff Platform Engineer variant that used the "after Architect titles were phased out" framing. Luke pushed back: it sounded like he'd been forced into a PE title by the org, and it explained a concept (engineers making architectural decisions) that the target engineering org already operated by.

## Build-from-scratch positioning

When a JD asks for "built end-to-end from scratch and scaled" or similar (a common senior-IC signal), Luke's strongest stories are **platform / team / internal-tooling builds, not customer-facing products**.

**Lead-with options**:

- **Reliability Engineering team from scratch** (Feb 2018 onwards): team build with internal-customer-platform mandate.  Strongest story.
- **Internal tooling shipped by Reliability Engineering** (monitoring aggregation platform, tech migration tracker, change management system): from-scratch products built during his tenure for engineering-team internal customers.
- **Centralised cyber security function** (Interim VP, 2022): organisational / function build.
- **Cloud-native zero-downtime deployment pipeline** (Integration Engineer, 2015): from-scratch infrastructure, but old.
- **Multifactor authentication solution** (FT Labs, post-2013 attack): from-scratch security infrastructure, very old.

**FastFT** (FT Labs, 2011–2014) — confirmed 2026-05-27 — was a customer-facing product built end-to-end, BUT Luke was a team contributor and not leading the build.  Acceptable to mention in passing (cv-extended.md already does); **don't position FastFT as a "I led a customer product from scratch" story** — that overclaims his role on it.

**UPP** is inherited architectural ownership of an existing platform (the Kafka backbone pre-dated his Architect-Content tenure), not greenfield design.  Per `[[luke-voice]]` 'don't claim greenfield on pre-existing systems': use "made architectural decisions on" / "worked on" framings, not "designed" / "architected".

**Rule of thumb**: for "product built end-to-end" JD signals, lean into the internal-platform / internal-tooling builds with honest framing ("built and scaled engineering platforms for internal customers — the FT's Reliability Engineering team and the tools it shipped, the centralised cyber security function, the monitoring aggregation platform").  Don't reach for FastFT as the lead-with story unless the JD specifically asks for very-old customer-product experience.

Related: [[user-skills-inventory]], [[luke-voice]], [[check-evidence-recency]].

## Unbackfilled Principal Engineer responsibilities (Apr 2022 – Mar 2025)

Throughout the Director and Interim VP roles, Luke retained the **unbackfilled Principal Engineer technical-direction responsibilities** for Cyber Security — providing all the technical direction the role usually requires while delegating day-to-day team management to senior engineers.

When (and whether) to surface this on a CV variant:

- For **IC-track variants** (Staff Engineer, Principal Engineer, Architect — roles whose deliverable is hands-on technical depth): pull this forward as the **first bullet** of both Director and Interim VP entries. Justifies the "decade of technical work" claim despite the Director/VP titles.
- For **management-track variants** (Director / Head / VP of Engineering): include as the **tail bullet** so the leadership-progression narrative still leads.
- For **advisory / consulting variants** (Senior Consultant / Principal Consultant at a strategy or advisory house, where the deliverable is client-facing engagements rather than IC technical output): **drop the chip entirely.** Stated 2026-05-26. The platform-engineering-decade framing in the Summary already carries the technical credentials needed for this audience; the unbackfilled-PE bullet adds noise about an internal staffing arrangement that doesn't translate to consulting hire decisions. Luke's framing: "I don't [think] for this role we need to lead with the backfilling for Principal Engineer in the director / VP jobs.  I'd question if they're valuable at all, but definitely wouldn't put them first."
- In `cv-extended.md` itself: it sits as the final bullet of both roles, so it's available to pull forward when the variant calls for it.

**Rule of thumb when deciding**: ask "does the JD's reader care about hands-on IC technical work?" If yes (Staff IC, Principal IC, Architect) → pull forward. If the role is mostly leadership-and-people → tail bullet. If the role is advisory / consulting / client-facing → drop entirely; the decade of FT platform-engineering work carries the technical credentials without needing the internal-staffing context.

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
