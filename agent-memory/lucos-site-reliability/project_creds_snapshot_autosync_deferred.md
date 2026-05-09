---
name: lucos_creds snapshot-auto-sync structural fix is deferred (lucas42 2026-05-09)
description: Architectural fix to LUCOS_DEPLOY_ENV_BASE64 staleness is deferred for cost; frame any architect consultation as deferred-not-planning
type: project
---

When raising or discussing the structural fix for `LUCOS_DEPLOY_ENV_BASE64` staleness (the dual-update gap behind the 2026-05-09 incident), don't pitch it as fresh planning work.

**Why:** lucas42 explicitly said on 2026-05-09 that the structural fix is *"a lot of work and not something we have time for now."* Bringing it to lucos-architect as if it's an open design question wastes the architect's time and disregards a clear product decision.

**How to apply:** When the architectural snapshot-auto-sync question gets consulted (whenever it does — no urgency until the documentation work in `lucas42/lucos_creds#304` is fully in), frame it to the architect as:
*"lucas42 has deferred this for cost reasons — is there a low-cost variant worth proposing, or should we accept the dual-update process indefinitely?"*

The architect's input there feeds into a triage decision between (a) revisiting if a cheap path exists, or (b) closing the structural option as `not_planned` with reasoning. Either outcome is fine; the framing should make clear there's no pressure to design a heavyweight solution.

Status: TBD note in the 2026-05-09 incident report (`lucas42/lucos/docs/incidents/2026-05-09-creds-ssh-key-crlf.md`); no follow-up issue filed yet.
