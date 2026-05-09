---
name: No "Lesson from {date}" parentheticals in instruction files
description: Keep persona/skill files lean — narrative lessons that prompted a rule belong in the commit message, not inline in the instruction text
type: feedback
originSessionId: 4b60f3f5-2d3f-4520-8c50-3dc971ae0b9f
---
When adding or strengthening a rule in a persona, skill, or other standing-instruction file, do **not** include a "(Lesson from YYYY-MM-DD: I did X and Y broke...)" parenthetical inside the file. Put the narrative explanation in the commit message instead. The instruction itself should be the rule plus a why/how-to-apply if needed — nothing more.

**Why:** persona files suffer from attention degradation as they grow (see ADR-0001 in lucos_claude_config and the related MEMORY.md note about long files). Inline lesson anecdotes are bloat that pushes every rule below them deeper into the file. Future agents reading the persona don't need the historical "this is why we wrote this rule" — they need the rule itself. The history is permanently preserved in the git commit message and can be retrieved when needed.

**How to apply:** When committing a rule change to a persona, skill, or standing-instruction file:
- The file edit contains: rule + why + how-to-apply, no "Lesson from ..." parenthetical.
- The commit message body contains the specific incident/example that motivated the change.

Existing inline lessons (in the coordinator persona and elsewhere) shouldn't be proactively cleaned up — only avoid adding new ones, and remove them opportunistically when editing nearby content.
