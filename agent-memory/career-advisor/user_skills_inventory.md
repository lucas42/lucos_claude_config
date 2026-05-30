---
name: user-skills-inventory
description: Luke's defensible skills, technologies, languages, and what he won't claim. Check this BEFORE asking Luke gap-fill questions about tech.
metadata:
  type: user
---

What Luke can honestly defend on a CV or in a technical interview. Captured from consultations during the 2026-05-19 / 2026-05-20 CV rebuild and JD-tailoring sessions. Update this file as new tech/methodologies are confirmed or excluded.

## Programming languages

**Comfortable, defensible on a CV**: Python · JavaScript / Node.js · PHP · Golang · Unix/Linux

**Dabbled, will not claim**: Java · Haskell · Prolog (and likely others — confirm before claiming if a JD requires a specific one).

**Ruby — hedge, don't list in Skills**: confirmed 2026-05-23 during a developer-platform Staff IC consultation. Luke has some FT exposure (enough to mention as adjacent if a JD asks) but would NOT pass a hard Ruby code-screen. Don't put Ruby in any CV's Skills section. For JDs that name Ruby as a primary language (the consultation's JD said "primarily in Go and Ruby"), treat it as a real gap with honest framing — adjacent only, don't claim.

## Web frameworks

**Django** — heavy use on personal projects (current / ongoing); some professional exposure on the FT Operational Intelligence team (~2015–2016). Confirmed 2026-05-22. Acceptable to list in Skills under Programming / Frameworks for JDs that name Django. **Don't claim** recent professional Django work; the personal-projects depth is what carries the weight today, so for JDs that probe specifics (years of Django at scale, specific Django features), hedge to "ongoing personal-project use plus earlier professional exposure".

## Databases / data stores

**Relational, comfortable**: MySQL · PostgreSQL

**Caching, comfortable**: Memcached (used on FT Integration Engineer)

**NoSQL — architect / decision-maker level** (platform used it, Luke owned the architectural trade-offs but engineers operated it; same pattern as Kubernetes):
- **GraphDB · MongoDB · Elasticsearch** — all used on the FT Universal Publishing Platform during the Architect - Content role. Confirmed 2026-05-21.

**NoSQL — hands-on on an operated team platform**:
- **Prometheus** — Reliability Engineering team. Time-series / metrics.
- **Neo4j** — Reliability Engineering team. Graph.

**NoSQL — hands-on on personal projects**:
- **Fuseki** (triplestore / SPARQL)
- **Typesense** (search)

**FT observability stack (for reference)**: confirmed 2026-05-23. The FT's observability stack across Luke's tenure was a mix of **Nagios, CloudWatch, Graphite, Grafana, and Prometheus**. **Datadog was NOT used** at the FT — don't claim Datadog as defensible based on FT-team experience. If a JD requires Datadog specifically, treat as a real gap (Luke ran the Observability team, so adjacent monitoring-tool fluency is defensible, but the specific Datadog product is not in his fingers).

**Where it can appear**:
- The "familiarity with SQL and NoSQL, and when to use each" type of JD ask: yes, fluently. Multiple NoSQL types across multiple roles.
- In a Skills section: yes, listed under Data & Platform / Databases. Acceptable to enumerate without claiming hands-on operations of all of them.

**Where it must NOT appear**:
- Don't claim "operating MongoDB / Elasticsearch clusters" or "deployed Mongo replica sets" — those are platform-engineer-on-the-data-team claims, not architect-of-the-overall-platform claims.
- For the Reliability Engineering ones (Prometheus, Neo4j) hands-on is fine but operations were a team activity, not individual.

**Will not claim**: Redis (Memcached is the adjacent substitute) · Druid · DynamoDB · Cassandra · Bigtable

## Frontend / UI

**Will not claim**: React (general JavaScript / Node.js is fine, but React specifically is not in Luke's history)

## Web servers / reverse proxies

**Apache and nginx — defensible**: confirmed 2026-05-27. Used extensively in two FT roles (Labs Developer Dec 2011 – Dec 2014; Integration Engineer Jan – Nov 2015) and still used today in personal projects. Acceptable to list in Skills under Cloud / Infrastructure or a Web Servers grouping for any JD that names Apache, nginx, or "web servers / reverse proxies" generically.

**Varnish — also defensible** (separately): two Varnish-related talks on cv-extended.md (Varnish User Group Berlin 2013; Varnish Summit LA 2016 where Luke collected the Varnish Innovation Award). Used heavily at FT Labs and in the FT's edge delivery layer.

**Will not claim**: IIS (no Windows-stack history); Tomcat (no Java-stack history).

## Configuration management / IaC

**Puppet — defensible**: confirmed 2026-05-23. Luke used Puppet extensively in two FT roles: Labs Developer at FT Labs (Dec 2011 – Dec 2014) and Integration Engineer at FT Strategic Products (Jan 2015 – Nov 2015). Acceptable to list in Skills under Programming & Systems for JDs that name Puppet. The Varnish User Group Berlin 2013 talk "One VCL to rule all our environments" specifically discusses Puppet-driven config consolidation across environments and is the strongest public reference point for this work.

**Other IaC tools (Terraform, Ansible, Chef, CloudFormation)**: not on the inventory; ask Luke before claiming if a JD requires a specific one.

## Containers / orchestration

**Comfortable, defensible**: Docker — used routinely across SaaS migrations, observability platforms, and personal projects.

**Architectural-only, NOT hands-on**: Kubernetes — Luke was Architect on the FT Universal Publishing Platform during the K8s migration and made the architectural decisions, but did not run clusters himself.

- **Where it can appear**: in the Architect-Content role bullet on cv-extended.md (the K8s-migration framing) because that's accurate to the role — the bullet is about the migration project, not a claim of hands-on Kubernetes knowledge.
- **Where it must NOT appear**: in a Skills section by default, alongside hands-on tools, or framed as "managed clusters" / "deployed to K8s" / "kubectl fluency".
- **Skills-section default = OMIT**: stated 2026-05-26. **Never list Kubernetes in the CV Skills section unless the JD explicitly names Kubernetes.** Default is to omit. Luke's stated framing: "It's one of my most tenuous claims, so let's only include it when actually asked for." When the JD does name Kubernetes, list "Kubernetes" plainly (no qualifier) but keep the role-bullet phrasing focused on the migration rather than on hands-on operations.
- **Tighter rule than previously held**: an earlier version of this rule said "for JDs that emphasise Kubernetes, lead with Docker in Skills" — that allowed Kubernetes-in-Skills for K8s-emphasising JDs. The tightened rule is stricter: omit by default, include only when the JD explicitly names Kubernetes, and even then keep the role-bullet honestly framed as migration-coordination rather than operations.
- **JD-triage signal — DO NOT weight Kubernetes mentions as positive fit indicators when prioritising spotted.md / new applications.** Stated 2026-05-28. Luke's architecture-only experience makes him less confident on K8s than the inventory's "can claim under conditions" framing might suggest. When ranking which roles to actively pursue, a JD that emphasises Kubernetes operations should NOT pull Luke toward applying — it's a tenuous claim, not a differentiator. Same applies to **Kafka / event-driven architecture** (see the Architecture areas section below for the same rule).

**Architectural-only, NOT hands-on**: AWS ECS — confirmed 2026-05-28. ECS was used by several FT teams Luke was on, especially the Reliability Engineering team. Luke took an architectural role on ECS adoption decisions; he was not hands-on with task definitions, service updates, or `aws ecs` CLI operations.

- **Where it can appear**: CV Skills section when a JD explicitly names ECS (or asks for advanced AWS container services). Same JD-triggered inclusion pattern as Kubernetes.
- **Where it must NOT appear**: claims of hands-on ECS operations ("deployed services to ECS", "wrote task definitions", "managed ECS clusters").
- **Skills-section default = OMIT**: include only when the JD names ECS specifically. Otherwise rely on Docker / generic "containerisation" framing.

## Cloud platforms

**AWS — architectural / strategic level only**: Luke's hands-on AWS work is the FT mobile-app cloud migration (Jan–Nov 2015), which is now 10+ years old. Since then AWS has been in his vocabulary at the architectural-decision / strategic level (not running infrastructure day-to-day). Confirmed 2026-05-22.

- **Can claim**: AWS architectural decisions, cloud-infra strategy, DevOps principles, cloud-native migrations.
- **Must NOT claim**: active hands-on AWS operations, current production AWS exposure, day-to-day `aws cli` / Terraform / CloudFormation work.
- **Where it can appear**: Skills section under Cloud & Platform; Integration Engineer role bullet (where the hands-on work happened).
- **Where it must NOT appear**: as a current / recent operational tool, or in a Career Break bullet claiming current AWS use (career-break agent fleet is self-hosted, not on AWS).
- **Don't add "(architectural)" parenthetical when listing AWS in Skills**: stated 2026-05-26. List "AWS" plainly; the FT Integration Engineer (Jan–Nov 2015) hands-on history is the warranty for the unqualified Skills listing, even though that work is now dated. The "architectural-only" caveat is preserved by NOT claiming current AWS operations elsewhere in the CV / cover letter; it doesn't need to be hedged in the Skills section itself. Adding "(architectural)" understates Luke's actual history.

**Azure — will not claim**: confirmed 2026-05-23 during a Staff IC consultation for a Microsoft-owned employer. Luke has no Azure exposure on record. For Microsoft-owned employers (where Azure is often the primary cloud), the honest framing is "AWS-architecturally at FT, cloud-native architecture generally" — don't list Azure in Skills, don't claim hands-on Azure use. The reliability + platform + container-orchestration framing carries the JD signal without needing to claim a specific Microsoft cloud.

**GCP — will not claim**: not on the inventory. Same rule as Azure — if a JD requires GCP, treat as a real gap.

## Virtualisation / VMware

**VMware — will not claim.** Confirmed 2026-05-30. The FT ran a Cisco UCS estate during Luke's tenure; he would occasionally use a web portal to create/destroy/modify VMs, but once a VM was up his interaction was via SSH and Puppet provisioning, not the hypervisor layer. He can't recall whether that portal was VMware-branded (vCenter/vSphere/ESXi) vs another virtualisation manager. So at best this is light, occasional *provisioning-level* usage of an unconfirmed hypervisor — not VMware administration (no HA/DRS, datastore design, vMotion, cluster ops). Don't put a VMware years-figure on a screening form; don't list VMware in Skills. If a JD names VMware as a hard requirement, treat as a real gap. **Cisco UCS ≠ VMware** — UCS is the compute hardware layer, VMware is the hypervisor that may or may not have run on it. Don't let UCS exposure get framed as VMware experience.

**JD-triage signal:** a role gating on *years-of-VMware* (especially paired with *years-of-Azure*) is screening for hands-on hybrid-infra ops, not security/platform leadership — a shape mismatch. Don't weight it as a fit. (Pulse Recruit "Head of Platform Security", 2026-05-30, dropped pre-application on exactly this: only two Easy-Apply questions were Azure-years + VMware-years, both misses.)

## Methodologies / engineering practices

**Comfortable**: TDD · Agile · Scrum · CI/CD · API-first design

**Loosely seen — hedge if claiming**: DDD (Domain-Driven Design) — has seen it in practice but hasn't personally led DDD adoption

**SLOs / SRE-book practices — DO NOT claim explicit SLO practice at FT**: The FT Reliability Engineering team (which Luke founded, Feb 2018 – Aug 2020) predates SRE-book adoption at the FT and operated in monitoring / availability / incident-response vocabulary, not explicit SLO / error-budget vocabulary. Confirmed by Luke 2026-05-22. For JDs asking for SLO experience, stick to "monitoring", "observability", "availability", "incident response" framing. Don't put "SLOs" in Skills sections or claim SLO design/rollout.

**"SRE" / "site reliability engineering" as a Skills term — DO NOT list.** Corrected 2026-05-29 (Luke pushed back on a Skills draft listing "site reliability engineering (SRE)"). Luke's team was named **Reliability Engineering**, and that's the defensible term — use **"reliability engineering"** in Skills, not "SRE" / "site reliability engineering". The two read as near-synonyms to an ATS, so "reliability engineering" still partially keyword-matches a JD that asks for "SRE practices" without overclaiming the SRE-book discipline. Same honest-framing reason as the SLO note above.

**DORA metrics — defensible at "started the foundational data work" level**: Confirmed 2026-05-26. During the PE-Reliability Engineering period (Feb 2018 – Aug 2020), Luke began work on enabling DORA metrics tracking across the FT's engineering teams. The focus was foundational — getting solid, dependable, standardised data in place so that individual team leaders could make decisions off the back of it — rather than rolling out DORA scorecards centrally or improving DORA outcomes at scale.

**Where it can appear**:
- Skills section under Developer Experience / Platform Engineering as "DORA metrics" or "developer-experience metrics".
- Cover-letter prose for DevEx / platform / SRE-leadership JDs that name DORA explicitly.
- Possible new evidence-story candidate for `evidence-stories.md`.

**Preferred phrasing**: "started the foundational data-standardisation work to enable DORA metrics tracking across the FT's engineering teams" / "set up dependable, standardised engineering data so individual team leaders could measure and act on DORA-style metrics". Honest framing: started, not delivered-at-scale.

**Don't claim**: "we improved DORA scores by X%", "we measured DORA across the engineering org", or "I rolled out DORA scorecards". The work was foundational data infrastructure, not end-to-end DORA delivery.

**SPACE metrics — not on inventory**: Luke didn't select SPACE in the gap-fill (2026-05-26). For JDs naming SPACE specifically, treat as familiar-with-the-framework gap.

**Lean / Value Stream Mapping — not on inventory**: Same gap-fill (2026-05-26). For JDs explicitly naming Lean/VSM as required methodology, treat as honest gap.

**Backstage / internal developer platforms — not on inventory**: Same gap-fill (2026-05-26). For JDs naming Backstage / Roadie / Port specifically, treat as honest gap (FT had its own internal tooling but Luke didn't claim Backstage-equivalent IDP experience).

## Technical decision-making documentation at FT

Stated 2026-05-22. The FT used **multiple / varied formats** across teams — some used ADRs, some used RFCs, some used informal design docs, some used none. There was no single house standard.

- **Can claim**: "architectural decision records", "technical proposals", "design documents", or umbrella phrasings like "wrote and reviewed technical proposals across teams".
- **Don't claim**: that the FT had a single RFC process or single ADR process.
- **For JDs that ask for RFCs specifically**: use "RFCs / technical proposals" or "written-decision-document processes" rather than asserting a specific format.

## Architecture areas

At architect / decision-making level (not necessarily hands-on configuration):

- **Event-driven architecture** — was architect on the FT Universal Publishing Platform which used Apache Kafka. Made decisions about event flows and data contracts; configuration and operations owned by engineers. **"Event-driven architecture" as a Skills term is fine** (architecture-level, defensible).
  - **"Apache Kafka" / "Kafka" in the Skills section — DO NOT name unless the JD explicitly names it.** Confirmed 2026-05-29 (Luke: "don't mention Apache Kafka unless it's mentioned in the JD … Kafka should be in my skills inventory as architecture only"). Same default-omit pattern as Kubernetes and ECS: Kafka is architecture-only, not hands-on. List the generic "event-driven architecture" instead; name Kafka only inside the Architect-Content role bullet (accurate to that role) or in Skills when the JD itself names Kafka.
  - **JD-triage signal — DO NOT weight Kafka mentions as positive fit indicators when prioritising spotted.md / new applications.** Stated 2026-05-28. Same rule as Kubernetes — Luke's architecture-only experience makes him less confident on Kafka hands-on than the "made architectural decisions" framing might suggest. A JD that emphasises Kafka data-plane / stream-processing operations should NOT pull Luke toward applying. Treat as a tenuous claim, not a differentiator.
- **Microservices** — 100+ at the FT publishing platform
- **API-first / REST APIs**
- **Real-time data processing** — FT was high-traffic but the volume was substantially less than the billion-events-per-day scale some platforms claim. Don't claim "billion-event-scale" without further confirmation.

## Software supply-chain security (SLSA, signed attestations, SBOM, dependency verification)

Confirmed 2026-05-22. **Conceptually current, not deep hands-on.** Luke is familiar with modern supply-chain hardening concepts (SLSA, signed attestations / commits, SBOM, dependency pinning, isolated build environments) at the architectural / decision-maker level, but has not shipped a SLSA programme at scale.

**Defensible adjacent evidence**:
- The personal agent fleet has supply-chain-adjacent discipline: per-app GitHub App credentials (scoped permissions per agent), audit-trailed commits, sandboxed VMs per persona, version-controlled instruction surfaces. This is the bridge to "I think this way about supply-chain security" even where the specific SLSA stack isn't in his fingers.
- General CI/CD experience across FT (cloud-native zero-downtime deploy pipeline, on-prem-to-SaaS dev-tooling migrations).

**For JDs that explicitly want SLSA / supply-chain hardening hands-on**: frame as honest gap with adjacent evidence (agent-fleet discipline + general CI/CD), same pattern as the regulated-pensions ISO 27001 honest-gap framing. Don't claim SLSA implementation at scale.

## Monitoring protocols (SNMP, WMI, JMX, JDBC, PerfMon)

Confirmed 2026-05-27 during a Senior Customer Technical Architect consultation at a hybrid-observability vendor. **Default rule: skip protocol-specific listings in Skills sections** for observability-vendor JDs that name them.

**Why:** The FT's monitoring stack was Nagios / CloudWatch / Graphite / Grafana / Prometheus — protocol fluency would have been adjacent (Luke ran the FT's monitoring strategy across all teams) but not in-the-fingers. Listing the protocols in Skills risks overclaiming hands-on competence in interviews.

**Where they DON'T appear**:
- CV Skills section by default — even when an observability-vendor JD lists them explicitly.
- CV role bullets — never.

**Where the absence is OK to compensate for**:
- Cover-letter prose can mention "the protocol landscape as the monitoring strategist" without claiming protocol-tinkerer depth.
- ATS keyword density: the observability / monitoring / metrics / log-aggregation / mixed-estate keyword cluster does the work the protocols would otherwise do.

**For JDs that demand specific protocol fluency**: treat as a real gap (same pattern as Datadog / Kubernetes / regulated-pensions ISO 27001). Frame as "protocol-aware from the buyer side" if asked, but don't claim depth.

## Active Directory / directory services / SSO

Confirmed 2026-05-27 during a Senior Customer Technical Architect consultation at a hybrid-observability vendor. **Defensible adjacency** via the FT's company-wide SSO migration to Okta during PE-Cyber (Sep 2020 – Sep 2021), which Luke "took over responsibility for... delivered on time and on budget" per cv-extended.md.

**Where it can appear**:
- Skills section as "identity and access management", "SSO / directory services", "Okta", or "directory integration" — for JDs that name Active Directory, AD, identity management, or directory services.
- Cover-letter prose for IAM-touching JDs as adjacent evidence.

**Don't claim**: AD administration, Windows-admin depth, day-to-day directory operations. The honest claim is strategic-direction-and-delivery of SSO migration that touched directory integration, not hands-on AD configuration.

**Useful framing**: "led the FT's company-wide SSO migration to Okta" or "delivered identity and access management programmes touching directory integration" — both are accurate to what's in cv-extended.md.

## DevSecOps tooling (SAST, SCA, secret scanning)

Confirmed 2026-05-26 during a Principal Product Security IC consultation. **Defensible to claim** as hands-on FT experience, not just architectural.

Luke had strategic ownership of the SAST / SCA / secret-scanning rollouts at the FT cyber team (rolled out across engineering's CI/CD pipelines, cyber team setting direction, engineering teams owning configuration). Critically: Luke was much more closely involved in the operational rollout discussions than he was with Kubernetes — so this is a different framing pattern from the Kubernetes-stays-architectural rule. The DevSecOps tools are operationally claimable, not just architecturally.

**Where it can appear**:
- Skills section under Cyber Security as explicit listed keywords ("SAST, SCA, secret scanning").
- CV bullets at PE-Cyber (now in cv-extended.md as of 2026-05-26 commit).
- Cover-letter prose where DevSecOps tooling is a JD signal.

**Preferred phrasing**: "rolled out SAST, SCA and secret-scanning across engineering's CI/CD pipelines" with the hedge "with the cyber team setting direction and engineering teams owning configuration" — that's the substantive-but-honest framing.

## Third-party / vendor cyber due diligence

Confirmed 2026-05-27 during a Staff Backend Engineer consultation for a risk-intelligence vendor whose product is buyer-side third-party DD.  **Defensible to claim** as hands-on FT Director-period experience.

As Cyber Security Director (Feb 2023 - Mar 2025), Luke led the cyber security due-diligence workstream of an organisation-wide procurement revamp at the FT.  Scope was every third-party engagement across the company; the wider revamp covered other DD types (data protection, sanctions, sustainability) that Luke wasn't responsible for.  Luke established a cyber risk triage that auto-approved low-risk suppliers and routed higher-risk ones to the cyber security team for more detailed assessment, balancing cyber risk against onboarding speed and team capacity.

**Where it can appear**:
- Skills section under Cyber Security as "third-party cyber due diligence", "supplier risk assessment", "vendor risk management", "GRC".
- CV bullets at Director level (now in cv-extended.md as of 2026-05-27).
- Evidence-story #10 in `evidence-stories.md` (added same day).
- Cover-letter prose / textarea answers where third-party DD / supplier vetting / vendor risk is a JD signal or company-domain match.

**Preferred phrasing**: "led the cyber security due-diligence workstream of an organisation-wide procurement revamp at the FT" - honest framing as the cyber side of a wider procurement initiative, not the whole revamp.

**Don't claim**: led the procurement revamp end-to-end; owned the other DD workstreams (data protection, sanctions, sustainability).

**For JDs that explicitly want third-party risk / supplier DD / vendor risk management experience**: defensible claim, not a gap.

**Buyer-side empathy angle**: at risk-intelligence / DD-vendor companies whose product is in this space, this is a strong "I have been your customer" line - Luke would have evaluated their product category as part of doing this work himself.

## Bug bounty programme management

Confirmed 2026-05-26. **Defensible to claim** as bug bounty programme management experience.

The FT had a bug bounty programme during Luke's cyber-leadership years (PE-Cyber onwards). Luke oversaw it: managed the vendor relationship and was the escalation point for tricky triage and payout decisions. The defensible claim is "oversaw" (not "ran personally"), but the vendor + escalation involvement is substantive enough to count as programme management on a CV or in a cover letter.

**Where it can appear**:
- Skills section under Cyber Security as "bug bounty programmes" or "bug bounty programme management".
- CV bullets at PE-Cyber (now in cv-extended.md as of 2026-05-26 commit).
- Cover-letter prose where bug bounty management is a JD signal. Concise letter version: "vendor management and escalation oversight on the FT's bug bounty programme". CV version mentions the triage and payout decisions explicitly.

**For JDs that explicitly want bug bounty programme management**: this is a defensible claim, not a gap. Use the "oversaw / vendor relationship / escalation point" framing rather than overclaiming day-to-day triage.

## AI / LLM platforms — concrete daily-use reference

Confirmed 2026-05-22. The personal multi-persona agent fleet is built on **Claude (Claude API / Claude Code)**. This gives Luke a concrete, daily, hands-on reference point for:
- The LLM-platform vendor itself (for applications to that specific vendor — Acme AI Lab in worked examples)
- Generic "experience using LLM platforms / GenAI tools" any JD asks for
- Agentic-AI guardrails framing (the work *is* on top of Claude)

**Where it can appear**:
- Cover-letter "why this company" paragraph for applications to the LLM-platform vendor itself: the lucos_agent fleet IS Claude, so the work of wrapping deterministic structure around a non-deterministic actor is the vendor's own product in Luke's hands today.
- CV Career Break section / Skills under Generative AI: acceptable to mention Claude (or the relevant LLM API) as the underlying platform when the JD wants concrete tooling.

**Don't overclaim**:
- Not a Claude API power-user in the "I've shipped a Claude-API-backed product" sense — this is personal-estate orchestration work.
- Not Constitutional AI / Responsible Scaling Policy / interpretability research expertise. Luke comes at AI safety from the security-engineering and platform-engineering side, not from the ML research side.

## Operational technology (OT) / ICS / SCADA / IEC 62443 / safety-critical

Confirmed 2026-05-28 during a public-sector transport cyber-architecture-lead consultation. **Genuine gap.** Luke's entire cyber and engineering background is **IT, not OT.** No industrial control systems, SCADA, safety-critical, or IEC 62443 experience.

**For JDs that name OT / ICS / SCADA / IEC 62443 / safety-critical infrastructure** (common in transport, utilities, energy, manufacturing, defence): treat as an honest gap. Luke's chosen handling (stated 2026-05-28): one candid sentence acknowledging the IT-not-OT background, paired with the transferable architecture-and-risk discipline and a willingness to ramp on the OT side. Don't dress it up; don't downplay it (these JDs make OT central).

**Don't claim**: IEC 62443 in the CV Skills section, or any OT/ICS/SCADA hands-on or architectural experience. The defensible IT-side standards (ISO 27001, NIST, CIS Controls, OWASP, MITRE ATT&CK, Cyber Essentials) carry the security-frameworks keyword work without reaching for the OT-specific one.

**Adjacent transferable evidence** (use to soften the gap, not erase it): FT-scale mission-critical systems under nation-state threat; incident & crisis management including business-continuity planning; architecture-and-risk rigour across a large mixed estate.

## Data platform / data engineering

Confirmed 2026-05-29. **Genuine gap.** Luke interviewed (Nov 2025) for a "Head of Platform" leadership role at a marketing-analytics company that turned out to be fundamentally a *data-platform* role; the interview exposed that data-engineering vocabulary and concepts ("data jargon") are not in his fingers, and he didn't get it.

**For JDs centred on data platforms / data engineering / analytics engineering** (data warehouses, ETL/ELT pipelines, dbt, data modelling, streaming/batch processing, lakehouse, etc.): treat as a genuine gap.
- **JD-triage signal — DO NOT weight a data-platform / data-engineering emphasis as a positive fit indicator** (same pattern as Kubernetes / Kafka). A "Platform" title that turns out to mean *data platform* is a mismatch, not a match, absent dedicated prep.
- **The "platform" ambiguity is the trap:** "Head of Platform" / "Platform Tech Lead" can mean infra/DevEx platform (Luke's wheelhouse) **or** *data* platform (a gap). Clarify which before investing tailoring or interview prep — ideally get a written job spec; last time there was none, which is how the data focus caught him out mid-interview.
- **If pursuing anyway:** transferable strength is platform / infrastructure / reliability / architecture leadership at scale; the data-engineering-specific depth is the gap. Luke's stated mitigation (2026-05-29) is to brush up on data-platform lingo beforehand. Honest framing, not bluffing — the Nov 2025 attempt failed precisely because the gap showed under questioning.

Related: [[user-role-framing]].

## Security frameworks / standards certifications (GIAC, ISC2, ISACA, ISA, CompTIA)

Confirmed 2026-05-28. **Luke holds none of these** — no CISSP, CISM/CISA, GIAC, CompTIA Security+, etc. For JDs that list cyber certifications as a requirement: claim none, and let demonstrated cyber-leadership experience carry it (a 5-year cyber-security-director-track record is itself the credential).

**Named security standards/frameworks — DO NOT list in Skills (no direct experience).** Corrected 2026-05-29 (Luke pushed back on a Skills draft that listed them). Luke confirmed he does **not** have direct experience of **ISO 27001, NIST, or CIS Controls** — don't put them in any CV Skills section, even as "familiarity". (This tightens an earlier, too-loose note that said framework "familiarity" was fine to list.) For the "compliance with frameworks and standards" type of JD ask, rely on the framework-agnostic security keywords Luke genuinely owns — security engineering, IAM/SSO, vulnerability management, DevSecOps (SAST/SCA/secret-scanning), security incident management, third-party/supplier risk, BCDR — rather than naming a specific standard. OWASP / MITRE ATT&CK weren't part of the 2026-05-29 correction, but apply the same conservative default: don't list a named framework unless Luke has confirmed direct experience of it.

## How to apply

Before asking Luke a gap-fill question about tech in any CV-tailoring consultation, **check this file first**. If a JD requires something that's already settled here (Luke does or doesn't claim it), apply that — don't re-ask. If a JD asks for something not on this list at all, it's a genuine gap — ask Luke whether honest evidence exists, then update this file with the answer.

Related: [[user-role-framing]], [[cv-rebuild]], [[cv-variant-content-rule]].
