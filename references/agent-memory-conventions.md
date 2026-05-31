# Agent memory conventions

How agents on the lucos team use their persistent memory directory. Applies to **every** persona.

Each persona has a persistent agent memory directory at `~/.claude/agent-memory/<persona>/`. Its contents persist across conversations and inform the persona's behaviour in future sessions.

## The index file: `MEMORY.md`

`MEMORY.md` is always loaded into the persona's system prompt. **Lines after 200 will be truncated**, so keep it concise.

**Trim trigger:** if `MEMORY.md` loads with a truncation warning (visible at session start as a note that only part of the file was loaded), trim it *before* saving any new memory in that session. Treat the warning as a hard signal to act, not background noise. There is no scheduled trim sweep — the trigger is the warning itself. Adding a new entry on top of an already-truncated index just pushes older content further out of view.

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

## Committing memory changes

**You do not need to commit or push memory edits yourself — and you should not.** A scheduled job (`scripts/commit-agent-memory.sh`, cron `*/15`) automatically commits and pushes all uncommitted changes under `agent-memory/` and `projects/` to `origin/main` every 15 minutes, committing to main via a temporary worktree regardless of which branch is checked out. After any write to `~/.claude/agent-memory/<persona>/` (new file, edit, delete, or a `MEMORY.md` update), **just leave it in the working tree**; the next cron tick (≤15 min) captures it.

Do **not** manually `git-as-agent` commit+push your `agent-memory/` changes in-session. The shared always-on VM keeps the working tree between session end and the next cron tick, so the job captures your edits durably — and a manual push *races* the cron, producing non-fast-forward errors once the cron has already pushed your work. (Eliminating that contention is why this step was removed.)

Caveats:
- **Durability window**: only edits made in the ≤15 min before the VM powers off or a cron run fails are at risk — narrow on an always-on VM, but non-zero. If you've written something you genuinely cannot lose and need it upstream *now*, that is the one time to commit+push `agent-memory/` by hand — and expect to rebase onto whatever the cron has already pushed.
- **Authorship**: memory commits are attributed to `lucos-system-administrator[bot]` ("Auto-commit agent memory updates"), not your persona bot. The file contents, not the commit message, carry the per-persona record.
- **Feature branches**: the job commits the working tree's `agent-memory/`/`projects/` content to main even if you are on a feature branch (it never pushes *to* the feature branch). Memory files are append-only and branches short-lived, so this is low-risk — but don't leave in-progress memory edits you don't want reaching main sitting in the working tree.

Note this auto-commit covers **only** `agent-memory/` and `projects/`. Config files outside those paths (`agents/`, `CLAUDE.md`, `settings.json`, workflow/reference docs) are **not** auto-committed and still need a deliberate `git-as-agent --app <persona-bot>` commit+push.

## When to access memory

- When the topic seems relevant, or the user references prior-conversation work.
- You **must** access memory when the user explicitly asks you to check, recall, or remember.
- If the user says to *ignore* or *not use* memory, do not apply remembered facts.
- Memory records can become stale. Before answering or building assumptions based solely on a memory, verify against the current state of the relevant files or resources. If a recalled memory conflicts with current information, **trust what you observe now** — and update or remove the stale memory rather than acting on it.

## Before recommending from memory

A memory that names a specific function, file, or flag is a claim that it existed *when the memory was written*. It may have been renamed, removed, or never merged. Before recommending it:

- If the memory names a file path: check the file exists.
- If the memory names a function or flag: grep for it.
- If the memory asserts the **lifecycle status of ongoing work** — phrases like "X is parked", "Y has shipped", "Z is blocked on W", "the migration is in progress", "this hasn't been implemented yet" — verify against GitHub issues, PRs, deployed code, or recent commits before relying on the status as a premise. Lifecycle-status memories age faster than any other kind, and they are especially load-bearing when they feed secondary decisions (e.g. "no consumer exists for this event yet *because the consuming system is parked*"). Treating a stale status as fact and reasoning forward from it produces architectural conclusions that are correct only by accident.
- If the user is about to act on your recommendation (not just asking about history), verify first.

"The memory says X exists" is not the same as "X exists now." Equally, "the memory says X is parked / done / blocked" is not the same as "X is parked / done / blocked **now**" — and the gap between those two has been the source of real architectural misjudgements (e.g. arguing "no live consumer exists, so file the event for future use" when in fact the consumer is ready to wire up today).

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
