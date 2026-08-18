---
name: commit-the-tools-own-serialisation
description: Before proposing a canonical-source/generated-artifact split for a file a tool rewrites, check the file's commit history — committing the tool's own output is usually the stable fixed point
metadata:
  type: feedback
---

When a tracked file is rewritten by a tool (config the app rewrites at startup, lockfiles, generated schemas), do **not** reach straight for a canonical-source + gitignored-live split. First check the file's own commit history for **key/line ordering across versions**. If the tool serialises deterministically, committing *the tool's own output* puts the file at a fixed point — subsequent rewrites are no-ops and the file stays clean with no extra machinery. A tracked hand-ordered canonical file is re-dirtied by **every** rewrite, which is the opposite of the goal.

**Why:** 2026-08-18, `lucos_claude_config#129`. I recommended splitting `settings.json` into a tracked canonical + ignored live file (following the repo's own `teams/*/config.canonical.json` precedent) plus a materialisation step. lucas42 overruled: *"I'd rather it gets committed directly into the repo, rather than relying on a brittle materialisation step."* He was right, and the evidence was one `git log` away — every hand-edited version 2026-04-02→2026-06-03 held a stable key order, and the tool's own order appeared for the first time in the live file. Committing that put it at the fixed point.

Two attached traps:
- **A precedent in the same repo is not automatically the right precedent.** `teams/*/config.json` is *regenerable runtime state* — nothing is lost if never restored. A *functional* file (hooks, permissions, anything the app reads to behave correctly) has no such property, so a canonical copy with no path back into the live file decays into fiction and a rebuilt machine silently loses the behaviour. Ask what breaks if the canonical copy is never applied.
- **A security objection scoped to one mechanism must not be stated as an objection to the goal.** My concern (auto-committing bypasses deliberate review of hook code = arbitrary execution) applied *only* to extending the auto-commit sweep — not to lucas42's actual decision, which kept commits deliberate. Check which branch your objection actually attaches to before raising it, and say so, or it reads as blocking a decision it doesn't touch.

**How to apply:** any "should this be tracked / should we split it" question about a machine-written file. `git log --format=%h <path>` then dump the structure of each version — it costs one command and it decides the design.

Related: [[shared-claude-checkout-ref-state]].
