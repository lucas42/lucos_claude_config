---
name: user-skills-inventory
description: Luke's defensible skills, technologies, languages, and what he won't claim. Check this BEFORE asking Luke gap-fill questions about tech.
metadata:
  type: user
---

What Luke can honestly defend on a CV or in a technical interview. Captured from consultations during the 2026-05-19 / 2026-05-20 CV rebuild and JD-tailoring sessions. Update this file as new tech/methodologies are confirmed or excluded.

## Programming languages

**Comfortable, defensible on a CV**: Python · JavaScript / Node.js · PHP · Golang · Unix/Linux

**Dabbled, will not claim**: Ruby · Java · Haskell · Prolog (and likely others — confirm before claiming if a JD requires a specific one).

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

**Where it can appear**:
- The "familiarity with SQL and NoSQL, and when to use each" type of JD ask: yes, fluently. Multiple NoSQL types across multiple roles.
- In a Skills section: yes, listed under Data & Platform / Databases. Acceptable to enumerate without claiming hands-on operations of all of them.

**Where it must NOT appear**:
- Don't claim "operating MongoDB / Elasticsearch clusters" or "deployed Mongo replica sets" — those are platform-engineer-on-the-data-team claims, not architect-of-the-overall-platform claims.
- For the Reliability Engineering ones (Prometheus, Neo4j) hands-on is fine but operations were a team activity, not individual.

**Will not claim**: Redis (Memcached is the adjacent substitute) · Druid · DynamoDB · Cassandra · Bigtable

## Frontend / UI

**Will not claim**: React (general JavaScript / Node.js is fine, but React specifically is not in Luke's history)

## Containers / orchestration

**Comfortable, defensible**: Docker — used routinely across SaaS migrations, observability platforms, and personal projects.

**Architectural-only, NOT hands-on**: Kubernetes — Luke was Architect on the FT Universal Publishing Platform during the K8s migration and made the architectural decisions, but did not run clusters himself.

- **Where it can appear**: in the Architect-Content role bullet on cv-extended.md ("Architected the move to Kubernetes…") because that's accurate to the role.
- **Where it must NOT appear**: in a Skills section, alongside hands-on tools, or framed as "managed clusters" / "deployed to K8s" / "kubectl fluency".
- **For JDs that emphasise Kubernetes**: lead with Docker in Skills, leave Kubernetes in the role bullet only, and flag the architecture-vs-operations distinction to Luke during gap consultation.

## Methodologies / engineering practices

**Comfortable**: TDD · Agile · Scrum · CI/CD · API-first design

**Loosely seen — hedge if claiming**: DDD (Domain-Driven Design) — has seen it in practice but hasn't personally led DDD adoption

## Architecture areas

At architect / decision-making level (not necessarily hands-on configuration):

- **Event-driven architecture** — was architect on the FT Universal Publishing Platform which used Apache Kafka. Made decisions about event flows and data contracts; configuration and operations owned by engineers.
- **Microservices** — 100+ at the FT publishing platform
- **API-first / REST APIs**
- **Real-time data processing** — FT was high-traffic but the volume was substantially less than the billion-events-per-day scale some platforms claim. Don't claim "billion-event-scale" without further confirmation.

## How to apply

Before asking Luke a gap-fill question about tech in any CV-tailoring consultation, **check this file first**. If a JD requires something that's already settled here (Luke does or doesn't claim it), apply that — don't re-ask. If a JD asks for something not on this list at all, it's a genuine gap — ask Luke whether honest evidence exists, then update this file with the answer.

Related: [[user-role-framing]], [[cv-rebuild]], [[cv-variant-content-rule]].
