---
name: reference-agent-root-equivalence-sandbox-102
description: lucos-agent is root-equivalent on prod hosts via docker (lucas42/lucos_agent_coding_sandbox#102). Test for a new access finding is "would fixing #102 fix this?", not "does it add exposure today?"
metadata:
  type: reference
---

`lucos-agent` is in the `docker` group on avalon, xwing and salvare, which makes it root-equivalent there. So are `docker-deploy` and `lucos-backups`; `lucas` and `debian` (avalon only) have sudo. Checked 2026-09-18: those are *all* the login accounts on those hosts. This is tracked in **lucas42/lucos_agent_coding_sandbox#102**, open; lucas42 wants it narrowed, not accepted.

**The test for whether an access finding is new: would fixing #102 fix it?** If not, it's a distinct vector and a separate ticket, however much blast radius the two share *today*.

**Why:** on 2026-09-18 I reported world-readable `lucos_creds_store` backups (which contain `data_key`) and then retracted, because every current reader is already root-equivalent via #102. team-lead rejected the retraction, correctly: narrowing #102 leaves the 644 archives readable with a plain read. My mistake was treating "no extra exposure today" as if it meant "not a separate problem". Filed as lucas42/lucos_backups#418.

**How to apply:**
- Before calling an access finding new, check #102. Then apply the test above. Don't drop the finding just because today's exposure is subsumed.
- The corollary is sequencing: a fix like #418's has to land **before or with** #102's remedy. Otherwise narrowing #102 turns the latent exposure into a live one.
- The reverse also holds: while #102 stands, no file-mode or backup-layout change bounds lucos-agent. It can mount any live volume (including `data_key` in `lucos_creds_store` on avalon). So don't present such fixes as containment for the agent.
