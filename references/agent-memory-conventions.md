# Agent memory conventions

How agents on the lucos team use their persistent memory directory. Applies to **every** persona.

Each persona has a persistent agent memory directory at `~/.claude/agent-memory/<persona>/`. Its contents persist across conversations and inform the persona's behaviour in future sessions.

## The index file: `MEMORY.md`

`MEMORY.md` is always loaded into the persona's system prompt. **Lines after 200 will be truncated**, so keep it concise.

`MEMORY.md` is an **index, not a memory**. Each entry should be one line, under ~150 characters, in the format:

```
- [Title](file.md) — one-line hook
```

Detailed memories live in **separate topic files** in the same directory (e.g. `debugging.md`, `patterns.md`, `feedback_pr_review.md`). Link to them from `MEMORY.md`. Never write memory content directly into `MEMORY.md` — the size limit means you'll lose older content as you add new content.

## Memory types

There are four discrete types of memory. Each memory file should declare its type in YAML frontmatter:

```markdown
---
name: {{memory name}}
description: {{one-line description — used to decide relevance in future conversations}}
type: {{user, feedback, project, reference}}
---

{{memory content}}
```

| Type | Purpose | When to save |
|---|---|---|
| `user` | Information about the user (lucas42) — role, preferences, knowledge, communication style | When you learn anything that helps you tailor future behaviour to lucas42 specifically |
| `feedback` | Guidance on how to approach work — corrections AND validated approaches | When the user corrects you or confirms a non-obvious approach worked |
| `project` | Project context, ongoing initiatives, decisions, deadlines | When you learn who is doing what, why, or by when |
| `reference` | Pointers to information in external systems (Linear, dashboards, etc.) | When you learn about resources outside the project directory |

For `feedback` and `project` memories, structure the body as: rule/fact first, then `**Why:**` line and `**How to apply:**` line. Knowing *why* lets you judge edge cases instead of blindly following the rule.

## What to save

- Stable patterns and conventions confirmed across multiple interactions.
- Architectural decisions and their rationale.
- Non-obvious gotchas and the workarounds you discovered.
- User preferences for workflow, tools, and communication style.

When you fix a recurring problem or hit an unexpected behaviour, ask whether it could happen again. If yes, save a memory.

## What NOT to save

- **Code patterns, conventions, architecture, file paths, or project structure** — these can be derived by reading the current project state.
- **Git history, recent changes, who-changed-what** — `git log` and `git blame` are authoritative.
- **Debugging solutions or fix recipes** — the fix is in the code; the commit message has the context.
- **Anything already documented in CLAUDE.md files** — duplication risks drift.
- **Ephemeral task details** — in-progress work, temporary state, current conversation context.
- **Speculative or unverified conclusions from reading a single file**.

These exclusions apply even when the user explicitly asks you to save something. If they ask you to save a PR list or activity summary, ask what was *surprising* or *non-obvious* about it — that is the part worth keeping.

## Organisation

- Organise memory **semantically by topic**, not chronologically.
- Update or remove memories that turn out to be wrong or outdated. Memory is a living document, not an audit log.
- Do not write duplicate memories. First check if there is an existing memory you can update before writing a new one.

## When to access memory

- When the topic seems relevant, or the user references prior-conversation work.
- You **must** access memory when the user explicitly asks you to check, recall, or remember.
- If the user says to *ignore* or *not use* memory, do not apply remembered facts.
- Memory records can become stale. Before answering or building assumptions based solely on a memory, verify against the current state of the relevant files or resources. If a recalled memory conflicts with current information, **trust what you observe now** — and update or remove the stale memory rather than acting on it.

## Before recommending from memory

A memory that names a specific function, file, or flag is a claim that it existed *when the memory was written*. It may have been renamed, removed, or never merged. Before recommending it:

- If the memory names a file path: check the file exists.
- If the memory names a function or flag: grep for it.
- If the user is about to act on your recommendation (not just asking about history), verify first.

"The memory says X exists" is not the same as "X exists now."

A memory that summarises repo state (activity logs, architecture snapshots) is frozen in time. If the user asks about *recent* or *current* state, prefer `git log` or reading the code over recalling the snapshot.

## Memory vs other forms of persistence

Memory is one of several persistence mechanisms. The distinction is that memory can be recalled in **future** conversations and should not be used for persisting information only useful within the current conversation.

- **Plans** — use a Plan rather than a memory to align with the user on an approach for a non-trivial implementation task in the current conversation.
- **Tasks** — use the task tools rather than a memory to break the current conversation's work into steps and track progress.

Memory is for what you'll want to remember **next time**. If it's only useful this session, it doesn't belong in memory.

## Persona-specific extensions

Personas may extend this reference with:

- Examples of what's typically worth saving for their workflow (e.g. the architect saves ADR rationales; the SRE saves recurring incident patterns).
- Memory directory pointer — every persona file should state its own `~/.claude/agent-memory/<persona>/` path.

Persona-specific guidance must not contradict the rules above.
