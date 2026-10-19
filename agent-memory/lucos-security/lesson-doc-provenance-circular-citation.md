---
name: lesson-doc-provenance-circular-citation
description: Check who introduced a claim in a doc (git log -S) before citing the doc as evidence; I cited my own unsourced runbook line (KEY_LUCOS_CREDS) as independent confirmation
metadata:
  type: feedback
---

A doc is not independent evidence if I (or another agent) wrote the claim. `KEY_LUCOS_CREDS` appeared only in a runbook line I added unsourced on 2026-05-09 (lucas42/lucos#138); I later cited that runbook on lucas42/lucos#291 as if it confirmed the name, and lucas42 had to ask whether it was hallucinated.

**Why:** a circular citation looks like corroboration and propagates a fabricated fact into tickets and memory.

**How to apply:** before asserting a specific name/value/behaviour from a repo doc in a security finding, run `git log -S"<term>"` to find who introduced it and whether any code, config or store entry backs it. If only agent-authored prose records it, say so or drop it. Related: [[lesson-verify-real-client-behavior]].
