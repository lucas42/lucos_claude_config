---
name: Check for deferred intent before raising TODO as an issue
description: When encountering a TODO/FIXME in code, check for signals that it is intentionally deferred rather than accidentally forgotten before raising it as an actionable issue.
type: feedback
---

Before raising a TODO or FIXME comment as a GitHub issue, look for "deferred intent" signals in the comment text:

- "For now, ..."
- "Until X is implemented..."
- "Placeholder ..."
- "Reserved for future ..."
- "TODO: implement when Y"
- "Intentionally ..."

**Why:** During the lucos_media_manager slug-validation work (May 2026), a TODO comment at `ControllerV3.java:79` was misread as actionable. The comment said "For now, always uses the current playlist" — this was intentional deferred design for future multi-playlist support, not a forgotten fix. Three PRs and three issues were raised incorrectly as a result.

**How to apply:** If a TODO contains any of the above signals, read the surrounding context and architectural docs before raising it as an issue. If uncertain, ask team-lead rather than filing immediately. "For now" and similar phrases are explicit signals that the author knew the limitation and chose to defer — they are not invitations to fix without further design input.
