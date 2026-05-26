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

## Configuration management / IaC

**Puppet — defensible**: confirmed 2026-05-23. Luke used Puppet extensively in two FT roles: Labs Developer at FT Labs (Dec 2011 – Dec 2014) and Integration Engineer at FT Strategic Products (Jan 2015 – Nov 2015). Acceptable to list in Skills under Programming & Systems for JDs that name Puppet. The Varnish User Group Berlin 2013 talk "One VCL to rule all our environments" specifically discusses Puppet-driven config consolidation across environments and is the strongest public reference point for this work.

**Other IaC tools (Terraform, Ansible, Chef, CloudFormation)**: not on the inventory; ask Luke before claiming if a JD requires a specific one.

## Containers / orchestration

**Comfortable, defensible**: Docker — used routinely across SaaS migrations, observability platforms, and personal projects.

**Architectural-only, NOT hands-on**: Kubernetes — Luke was Architect on the FT Universal Publishing Platform during the K8s migration and made the architectural decisions, but did not run clusters himself.

- **Where it can appear**: in the Architect-Content role bullet on cv-extended.md ("Architected the move to Kubernetes…") because that's accurate to the role.
- **Where it must NOT appear**: in a Skills section, alongside hands-on tools, or framed as "managed clusters" / "deployed to K8s" / "kubectl fluency".
- **For JDs that emphasise Kubernetes**: lead with Docker in Skills, leave Kubernetes in the role bullet only, and flag the architecture-vs-operations distinction to Luke during gap consultation.

## Cloud platforms

**AWS — architectural / strategic level only**: Luke's hands-on AWS work is the FT mobile-app cloud migration (Jan–Nov 2015), which is now 10+ years old. Since then AWS has been in his vocabulary at the architectural-decision / strategic level (not running infrastructure day-to-day). Confirmed 2026-05-22.

- **Can claim**: AWS architectural decisions, cloud-infra strategy, DevOps principles, cloud-native migrations.
- **Must NOT claim**: active hands-on AWS operations, current production AWS exposure, day-to-day `aws cli` / Terraform / CloudFormation work.
- **Where it can appear**: Skills section under Cloud & Platform; Integration Engineer role bullet (where the hands-on work happened).
- **Where it must NOT appear**: as a current / recent operational tool, or in a Career Break bullet claiming current AWS use (career-break agent fleet is self-hosted, not on AWS).

**Azure — will not claim**: confirmed 2026-05-23 during a Staff IC consultation for a Microsoft-owned employer. Luke has no Azure exposure on record. For Microsoft-owned employers (where Azure is often the primary cloud), the honest framing is "AWS-architecturally at FT, cloud-native architecture generally" — don't list Azure in Skills, don't claim hands-on Azure use. The reliability + platform + container-orchestration framing carries the JD signal without needing to claim a specific Microsoft cloud.

**GCP — will not claim**: not on the inventory. Same rule as Azure — if a JD requires GCP, treat as a real gap.

## Methodologies / engineering practices

**Comfortable**: TDD · Agile · Scrum · CI/CD · API-first design

**Loosely seen — hedge if claiming**: DDD (Domain-Driven Design) — has seen it in practice but hasn't personally led DDD adoption

**SLOs / SRE-book practices — DO NOT claim explicit SLO practice at FT**: The FT Reliability Engineering team (which Luke founded, Feb 2018 – Aug 2020) predates SRE-book adoption at the FT and operated in monitoring / availability / incident-response vocabulary, not explicit SLO / error-budget vocabulary. Confirmed by Luke 2026-05-22. For JDs asking for SLO experience, stick to "monitoring", "observability", "availability", "incident response" framing. Don't put "SLOs" in Skills sections or claim SLO design/rollout.

## Technical decision-making documentation at FT

Stated 2026-05-22. The FT used **multiple / varied formats** across teams — some used ADRs, some used RFCs, some used informal design docs, some used none. There was no single house standard.

- **Can claim**: "architectural decision records", "technical proposals", "design documents", or umbrella phrasings like "wrote and reviewed technical proposals across teams".
- **Don't claim**: that the FT had a single RFC process or single ADR process.
- **For JDs that ask for RFCs specifically**: use "RFCs / technical proposals" or "written-decision-document processes" rather than asserting a specific format.

## Architecture areas

At architect / decision-making level (not necessarily hands-on configuration):

- **Event-driven architecture** — was architect on the FT Universal Publishing Platform which used Apache Kafka. Made decisions about event flows and data contracts; configuration and operations owned by engineers.
- **Microservices** — 100+ at the FT publishing platform
- **API-first / REST APIs**
- **Real-time data processing** — FT was high-traffic but the volume was substantially less than the billion-events-per-day scale some platforms claim. Don't claim "billion-event-scale" without further confirmation.

## Software supply-chain security (SLSA, signed attestations, SBOM, dependency verification)

Confirmed 2026-05-22. **Conceptually current, not deep hands-on.** Luke is familiar with modern supply-chain hardening concepts (SLSA, signed attestations / commits, SBOM, dependency pinning, isolated build environments) at the architectural / decision-maker level, but has not shipped a SLSA programme at scale.

**Defensible adjacent evidence**:
- The personal agent fleet has supply-chain-adjacent discipline: per-app GitHub App credentials (scoped permissions per agent), audit-trailed commits, sandboxed VMs per persona, version-controlled instruction surfaces. This is the bridge to "I think this way about supply-chain security" even where the specific SLSA stack isn't in his fingers.
- General CI/CD experience across FT (cloud-native zero-downtime deploy pipeline, on-prem-to-SaaS dev-tooling migrations).

**For JDs that explicitly want SLSA / supply-chain hardening hands-on**: frame as honest gap with adjacent evidence (agent-fleet discipline + general CI/CD), same pattern as the regulated-pensions ISO 27001 honest-gap framing. Don't claim SLSA implementation at scale.

## DevSecOps tooling (SAST, SCA, secret scanning)

Confirmed 2026-05-26 during a Principal Product Security IC consultation. **Defensible to claim** as hands-on FT experience, not just architectural.

Luke had strategic ownership of the SAST / SCA / secret-scanning rollouts at the FT cyber team (rolled out across engineering's CI/CD pipelines, cyber team setting direction, engineering teams owning configuration). Critically: Luke was much more closely involved in the operational rollout discussions than he was with Kubernetes — so this is a different framing pattern from the Kubernetes-stays-architectural rule. The DevSecOps tools are operationally claimable, not just architecturally.

**Where it can appear**:
- Skills section under Cyber Security as explicit listed keywords ("SAST, SCA, secret scanning").
- CV bullets at PE-Cyber (now in cv-extended.md as of 2026-05-26 commit).
- Cover-letter prose where DevSecOps tooling is a JD signal.

**Preferred phrasing**: "rolled out SAST, SCA and secret-scanning across engineering's CI/CD pipelines" with the hedge "with the cyber team setting direction and engineering teams owning configuration" — that's the substantive-but-honest framing.

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

## How to apply

Before asking Luke a gap-fill question about tech in any CV-tailoring consultation, **check this file first**. If a JD requires something that's already settled here (Luke does or doesn't claim it), apply that — don't re-ask. If a JD asks for something not on this list at all, it's a genuine gap — ask Luke whether honest evidence exists, then update this file with the answer.

Related: [[user-role-framing]], [[cv-rebuild]], [[cv-variant-content-rule]].
