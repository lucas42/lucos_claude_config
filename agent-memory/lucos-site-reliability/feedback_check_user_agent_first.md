---
name: Check user-agent first when hunting a misbehaving client
description: When investigating which lucos system is generating malformed/unwanted HTTP requests, look at the user-agent header in access logs before forming a hypothesis about the client implementation
type: feedback
---

When investigating "which lucos service is sending these malformed requests?" — **check the `User-Agent` header in the receiver's access logs before forming any hypothesis about the client.**

**Why:** I had circumstantial evidence (env var name, Python-style URL appending pattern) that pointed at `lucos_schedule_tracker_pythonclient` for the doubled-path POSTs in `lucas42/lucos_schedule_tracker#68` (2026-05-01) and shipped a ticket naming it as the suspect. lucas42 then pointed out the user-agent in the receiver's access logs was `node` — meaning the offending consumer was a Node service (likely `lucos_time`), not a Python one. The user-agent header was already in the logs I was reading; I just didn't bother to check it.

**How to apply:** Whenever an issue or investigation comes down to "which client is doing this?", the very first diagnostic step is to read the user-agent on the offending requests. Common failure modes my earlier reasoning hit:
- Pattern-matching on env var names (`SCHEDULE_TRACKER_ENDPOINT` → "must be the Python client") without checking which language's URL-joining quirks fit the actual evidence.
- Naming a "prime suspect" library/service in the issue body before the user-agent was inspected.
- Implicitly conflating "what container hosts this binary" (e.g. `lucos_docker_health_app`, which I knew posts to schedule-tracker) with "which language is the binary written in" (Go, not Node).

ADR-0001 (`lucas42/lucos/docs/adr/0001-user-agent-strings-for-inter-system-http-requests.md`) requires lucos services to identify themselves by system name in user-agent. Any consumer that doesn't is itself an ADR-0001 violation worth flagging — but even a bare `node` is enough to rule out half the possible services in 30 seconds, which is much faster than reasoning from indirect evidence.
