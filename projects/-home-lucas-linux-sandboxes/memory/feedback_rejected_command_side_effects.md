---
name: feedback-rejected-command-side-effects
description: "A \"rejected\"/interrupted compound Bash command can still have partial (or full) side effects — verify state, never assert \"it didn't run\""
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b015b004-ba6f-4643-9a45-91fe3740c990
---

A `Bash` tool call that returns **"The tool use was rejected"** (or is otherwise interrupted) does **not** guarantee that nothing happened. If the command was a multi-step script with side-effecting calls (creating a GitHub issue, board mutations, posting comments), **earlier steps may have already executed** before the interruption.

Concrete failure (2026-06-08): a single Bash script created issue `lucos_backups#314` (host-rsync), added it to the project board, *then* the tool returned "rejected." I read "rejected" as "nothing was created" and told lucas42 "I didn't create the issue." In fact #314 existed AND was on the board (created 19:45:49). lucas42 caught the orphaned issue later. I had to close it not-planned and delete the board item.

**Why it happened:** I asserted an outcome ("didn't create it") from the *tool verdict* rather than from the *actual state*. A compound write command is not atomic — a "rejected"/interrupted verdict says nothing reliable about partial side effects.

**How to apply:**
- After any side-effecting command returns rejected/interrupted/empty, **re-fetch the actual state** (does the issue/PR/board-item exist?) before asserting anything about what did or didn't happen. Never say "I created/didn't create X" from the verdict alone.
- Prefer **isolating side-effecting creation** (e.g. `POST .../issues`) as its own call, capture the URL, *then* do board setup in a separate step — so an interruption can't orphan a created-but-unconfigured artifact.

Sibling of [[feedback_treat_empty_tool_output_as_unknown]] (empty/late result = unknown) and [[feedback_refetch_before_accusing]] (re-fetch before asserting another's state). Same root: trust observed state, not the tool's framing.
