---
name: Audit tool architecture is intentional
description: The lucos_repos audit tool only creates issues by design — do not treat this as a bug or propose changes without architect review
type: feedback
---

Do not assume missing functionality in lucos_repos is a bug. The audit tool only creates GitHub issues — it never closes or updates them. This is by design, not a missing feature.

**Why:** Proposing auto-close as a "bug fix" on lucas42/lucos_repos#248 was a significant architectural departure that should have gone through the architect first. The tool's write scope is a deliberate design choice.

**How to apply:** Before raising issues that propose changing how an existing tool interacts with external systems (GitHub, APIs, etc.), consult `lucos-architect`. "It doesn't do X" is not the same as "it should do X." Also applies to any changes that would expand a tool's write scope.
