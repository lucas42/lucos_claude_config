---
name: Consult github-workflow.md before scripting GitHub API calls in messages
description: When composing instructions for agents that involve GitHub API calls (especially gh-as-agent), consult references/github-workflow.md first rather than recalling the syntax from memory
type: feedback
originSessionId: 4546d193-c4f0-4a71-9598-7cda7d2cd5e6
---
When composing a SendMessage that tells an agent to run a `gh-as-agent` command (or any GitHub API call), **read the relevant section of `~/.claude/references/github-workflow.md` first** — do not recall the API syntax from memory.

**Why:** During the 2026-04-28 backups incident, I instructed SRE to flip PR #117 from draft to ready-for-review using `gh-as-agent --method PATCH -F draft=false`. That endpoint silently ignores the `draft` field — flipping draft state requires the GraphQL `markPullRequestReadyForReview` mutation. The doc had this exact gotcha documented at lines 80–91 ("Marking draft PRs as ready for review"). SRE caught and worked around it, but only because they also consulted the doc; my instruction would otherwise have been a silent no-op. The instruction was correct; my recall was wrong.

**How to apply:**
- Before sending an agent a `gh-as-agent` command in plain text, scan `references/github-workflow.md` for the relevant operation (PR draft flip, PR creation, issue comment, label management, etc.) and lift the canonical syntax verbatim.
- Don't trust shortest-path memory for fields like `draft`, `merged_via_squash`, `state`, etc. — many of them have surprising "silently ignored" behaviour on the REST PATCH endpoint.
- If the operation isn't in the doc, ask the relevant teammate (most likely `lucos-system-administrator` for new operational patterns) before guessing.
