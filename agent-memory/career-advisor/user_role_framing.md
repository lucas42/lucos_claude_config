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

## Vendor-side customer-facing technical roles (Customer Technical Architect, Solutions Architect, Sales Engineer)

Confirmed 2026-05-27 during a consultation for a Senior Customer Technical Architect role at a hybrid-observability vendor (Acme Observability in worked-example terms).

This is a role archetype Luke is positioning for as part of broadening the funnel. The deliverable is a customer-facing trusted-advisor engagement (post-sales solutioning, advisory, demos, training, troubleshooting, product-feedback-loop) rather than IC engineering or people management. The 10-15-years-experience bar fits Luke's senior IC tier.

### Positioning approach

**Lead with domain expertise, no title-trajectory narrative.** Skip the "deliberate technical re-focus" / "Director → IC" framing. Anchor the Summary on the domain match (observability, monitoring, cyber, IAM — whatever the vendor sells) and let the dates carry seniority. Trying to explain Director → Customer Technical Architect adds noise; recruiters at vendors read Luke's history as a buyer-side credential, not a title-step-down.

**Reframe internal-advisory as customer-facing-adjacent.** Luke has substantial internal-advisory evidence: "advised on security concerns across all the FT's engineering teams" (PE-Cyber), "senior stakeholder management, acting as a bridge between business and engineers" (Director), conference talks, panel moderation, cross-functional partnership with Editorial / B2B / Tech (Architect-Content). None of this is external-paying-customer experience — but it's adjacent enough to carry the reframe. **Don't add an honest-gap line** about external-customer-newness in the CV; let the evidence stand and address the gap conversationally if the recruiter probes.

**Skills section pattern: include a "Cross-functional Practice" category** as the fifth/last slot. Populate with "technical advisory across engineering teams, senior stakeholder management, conference-style technical communication, vendor relationship management, [domain-specific IAM / IaC / etc.]". This is the keyword-density layer for the customer-facing reframe.

### Buyer-side empathy framing

For any role at a vendor whose product Luke would have evaluated or operated at the FT, the unfair-advantage angle is **"I have been your customer"** — implicitly. Examples of buyer-side history Luke can draw on:

- **Monitoring / observability vendors** (Datadog, New Relic, Dynatrace, Splunk, Acme Observability): FT Reliability Engineering team, monitoring aggregation platform, QCon 2020 "Monitoring All the Things" talk, end-of-life roadmaps for monitoring tools.
- **Code hosting / DevTools vendors** (GitHub, GitLab, Atlassian): the FT's Code Hosting and Issue Tracking SaaS migrations, vendor evaluation.
- **IAM vendors** (Okta, Auth0): the FT's SSO migration to Okta.
- **Security tooling vendors** (Snyk, Veracode, GitGuardian, Endor Labs): the FT's SAST / SCA / secret-scanning rollouts.
- **AI platform vendors**: the personal agent fleet (already settled in [[user-skills-inventory]]).

**How to deploy:** don't say "I have been your customer" in those words — too sales-pitchy. Lead the Summary with the buyer-side story and trust the reader to draw the inference. Worked example from this consultation: *"Spoke at QCon London 2020 on Monitoring All the Things - the mixed-estate observability problem hybrid-monitoring vendors exist to solve."*  One sentence; reader draws the inference on their own.

### What NOT to do

- **Don't lean on "Director" or "VP" as the headline credential.** Vendors hiring customer-facing technical architects care about technical and customer credibility, not org-chart altitude. Older titles (Principal Engineer, Architect) often carry more weight than recent management titles for this archetype.
- **Don't claim external-customer-facing experience Luke doesn't have.** Reframe internal-advisory as adjacent; don't dress it up as paying-customer engagement.
- **Don't apologise for the gap in the CV.** Let the adjacent evidence carry the weight and leave the external-customer-is-new conversation for the recruiter call.

Related: [[user-skills-inventory]], [[check-evidence-recency]], [[user-cover-letter-patterns]].

## Backend IC roles at vendors whose product Luke would have evaluated as a buyer

Confirmed 2026-05-27 during a Staff Backend Engineer consultation at a risk-intelligence vendor whose product is buyer-side third-party DD.

**Distinct from the vendor-side customer-facing technical roles framing above** (which centres buyer-side empathy as the *central pitch* of a CTA / SA / SE archetype).  For a backend IC role at the same archetype of vendor, the role criteria (backend engineering at scale, distributed systems, AI tooling, specific stack) are what gets Luke screened in; the buyer-side empathy is the **differentiator** that lifts the application above other qualified candidates rather than being the central pitch itself.

### Positioning approach

- **Lead the textarea / cover-letter opener with the buyer-side angle.**  It answers the implicit "what makes you different from other qualified backend engineers?" question with concrete evidence the recruiter can't easily anticipate.  For risk-intelligence / DD vendors, story #10 in `evidence-stories.md` is the strongest opener.
- **Back it up with the backend-engineering credibility in the second beat.**  UPP-scale microservices, distributed systems, platform engineering — this is what the JD's role criteria actually screen for.  Don't skip it.
- **Keep the role's primary technical signals foregrounded in the CV Summary and Skills.**  Architecture, distributed systems, AI tooling — whatever the JD prioritises.  The buyer-side angle is for the textarea / cover-letter prose, not for the CV's top-of-page positioning.

### What NOT to do

- **Don't lead the CV Summary with the buyer-side angle.**  Recruiters scan the Summary for the role criteria first.  If the Summary opens with "I have been your customer" framing, it reads as a domain-fit pitch rather than a technical-IC pitch and risks screening out on tech-stack assumptions.
- **Don't say "I have been your customer" in those words.**  Lead with the evidence and let the reader draw the inference.  Same pattern as the customer-facing-technical-roles framing.
- **Don't claim depth in the vendor's specific product.**  Buyer-side empathy is about the problem space, not their product.  If Luke didn't evaluate or use the specific vendor's product, don't pretend otherwise.

### Worked example (textarea answer for a risk-intelligence vendor Staff Backend Engineer)

Opening paragraph led with the third-party cyber due-diligence workstream Luke owned at the FT (story #10 in the library), framing it as "the buyer side of the problem [the vendor] is solving."  Second paragraph backed it with UPP-scale platform-engineering credibility (story #3 — microservices, Kafka, K8s migration).  Third paragraph was the AI-tooling current focus (the JD's #1 signal: Claude Code as daily driver).  No "I have been your customer" phrase used — the evidence carried the inference.

Related: [[user-skills-inventory]] (third-party cyber DD section), [[user-cover-letter-patterns]], [[check-evidence-recency]].

## Dual-domain roles: unify the year-claim rather than adding two domain-claims

Confirmed 2026-05-29 on a Platform Engineering Director application that co-weighted platform/infrastructure leadership **and** security engineering roughly evenly (the team even sat inside an Information Security group).

When a JD wants two of Luke's domains at once (e.g. platform + security, or architecture + cyber), **frame the headline as a single unified claim** — "over a decade leading platform, reliability and security engineering at the FT" — and surface the more recent specialism via the **job title** ("most recently Cyber Security Director"), rather than stating two separate additive "[N] years of [domain]" claims.

**Why:** Luke's cyber years (PE-Cyber Sep 2020 onwards) sit *inside* the broader FT engineering decade. Claiming "a decade of platform engineering" AND "5 years of cyber security leadership" as two separate numbers double-counts the 2020–2022 period and breaches the [[overlap-years-claim]] ceiling — it implies parallel tenures that didn't exist. One unified claim covering the whole tenure, with the recent title carrying the specialism signal, is honest and reads as more senior (breadth held continuously, not two short stints).

**How to apply:** when picking the year-claims framing (the `/tailor` Step 8 decision), if the role wants two domains co-equally, default to the unified-claim framing instead of choosing one additive domain-number. Reserve the discrete "5 years cyber" / "3 years cyber" additive framings for roles that want *one* domain foregrounded.

## Level-positioning when the JD level doesn't match recent titles

- **Director → Staff IC** (e.g. cv-staff-engineer.md for a fintech Staff Engineer JD): frame as "deliberate technical re-focus", lead with PE-concurrent bullet, surface architecture and engineering above strategy/people-management.
- **Director → Director/Head/VP of Engineering** (e.g. cv-engineering-director.md for a platform-engineering Director JD): lean into the Director title and multi-team leadership; soften "manager of managers" per above; pull architecture experience (especially Architect - Content / publishing platform) up the page.
- **Director → Engineering Manager / Tech Lead Manager** (not yet built): expected to need a "leading through senior leads" middle-ground framing.

## Retail-sector roles: surface the early retail experience

Confirmed 2026-05-29 during a Software Engineering Manager consultation at a major UK retailer.

For **retail-sector roles**, include Luke's early retail job (J Sainsbury plc, Customer Services Assistant / tills, May 2005 – Dec 2005) as a **single one-liner in `# Earlier Career`** as a sector signal. Format: `- J Sainsbury plc - **Customer Services Assistant**: May 2005 - December 2005`. This is per the variant-content rule (pull forward Earlier Career entries directly relevant to the target industry) — the rest of the pre-Assanka Earlier Career entries (student societies, work placements) stay dropped.

**Only call it out in a cover letter / textarea answer** if either (a) the role is at Sainsbury's specifically, or (b) the role has a particular focus on **in-store technology**. For a generic retail / e-commerce engineering role at a *different* retailer, the one-liner CV signal is enough — don't mention the till experience in prose (it isn't a genuine connection to *that* employer, and an EM/e-commerce role isn't in-store-tech-focused).

Related: [[cv-variant-content-rule]].

## Security-leadership roles that split compliance ownership to a peer

Confirmed 2026-06-01 (a payments-SaaS Head of Security role reporting to a VP, peering with a Head of Compliance). When a security-leadership JD **explicitly splits compliance-framework ownership to a separate role/peer** — the Head of Compliance owns frameworks/audits/evidence, the security role owns posture, tooling and response — the named-compliance-framework gap (ISO 27001 / SOC 2 / PCI DSS / HIPAA, which Luke doesn't own; see [[user-skills-inventory]]) is **substantially neutralised**.

**How to apply:** lead the CV with security posture / incident response / vulnerability management / tooling (Luke's strengths); omit named compliance frameworks from Skills (no direct ownership); and surface his genuine **compliance-function collaboration** (incidents, procurement DD, AI governance, ad-hoc risk — see [[user-skills-inventory]]) as evidence of working *alongside* compliance rather than owning it. This answers the "work closely with the Head of Compliance" expectation without overclaiming. Don't reach for the named frameworks just because the JD lists them as company-level regulatory context.

## How to apply

Check this file before drafting Summary paragraphs and before deciding how to reframe the Director / Interim VP bullets. If a JD raises a positioning question not addressed here, ask Luke and update this file with the answer so future variants inherit it.

Related: [[user-skills-inventory]], [[cv-variant-content-rule]], [[cv-rebuild]].
