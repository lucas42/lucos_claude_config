---
name: Don't spawn teammates as subagents
description: When you need to interact with another lucos-* persona, use SendMessage. Never use the Agent tool with subagent_type=lucos-*.
type: feedback
---

When you need to interact with another `lucos-*` persona during a workflow (request a code review, escalate to security, ask for an SRE assessment), use **`SendMessage` with `to: "<persona-name>"`**. They are already running teammates on the same team. **Never** use the `Agent` tool with `subagent_type: "lucos-..."` to spawn them as a fresh subagent.

**Why:** A fresh `Agent`-spawned subagent has no shared inbox with the team. The "message" arrives as a one-shot stateless prompt; the reply comes back to you alone as a tool-call return, not visible to team-lead or the rest of the team. The coordinator loses sight of the work, the subagent re-bills full persona load every time, and multi-round flows (PR review iterations) become impossible to drive coherently. Same persona name, completely different mechanism.

Provenance: 2026-05-10. While implementing lucos_claude_config#58 (ADR-0003 Stage 4) I called `Agent({subagent_type: "lucos-code-reviewer"})` twice instead of `SendMessage({to: "lucos-code-reviewer"})`. The reviews ran and the PR shipped — so the failure was invisible at the surface — but it bypassed the team flow. Two contributing factors made it easy to do wrong:

1. `SendMessage` was a deferred tool (had to `ToolSearch` for it); `Agent` was loaded eagerly. The wrong tool was on the surface; the right one wasn't.
2. The `Agent` tool description lists `lucos-*` personas as `subagent_type` values, making the wrong choice look canonical at the point of use.

**How to apply:** Whenever a workflow says "send a message to the X teammate", reach for `SendMessage` first — never `Agent`. If `SendMessage` isn't loaded, `ToolSearch` for it (`select:SendMessage`) before doing anything else; don't substitute `Agent` because it's the tool that's already there. Instruction updates landed alongside this memory: `pr-review-loop.md` Steps 1 & 4, `agents/workflows/implement-issue.md` Step 9, and a new "Don't spawn teammates as subagents" section in `references/teammate-communication.md`.
