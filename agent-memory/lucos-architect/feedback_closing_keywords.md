---
name: Closing keywords only for completing issues
description: Use Refs not Closes when a PR fulfils a prerequisite (e.g. ADR) rather than completing the full issue
type: feedback
---

Use `Refs #N` (not `Closes #N`) when a PR fulfils a prerequisite for an issue rather than completing it. ADRs and design documents are almost always prerequisites — the implementation issue should stay open for the actual code change.

**Why:** PR #251 (ADR-0004) used `Closes #248`, which auto-closed the implementation issue when the ADR merged. The ADR was a prerequisite, not the implementation itself. Team-lead had to reopen #248 manually.

**How to apply:** Before writing a PR body, ask: does this PR *complete* the issue, or *contribute towards* it? For ADRs, design docs, and other prerequisite work, always use `Refs #N`.
