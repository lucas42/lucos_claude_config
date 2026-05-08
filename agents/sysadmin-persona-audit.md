# Persona Consistency Audit Procedure

This file is read by `lucos-system-administrator` when running a persona consistency audit.

## When to Run

- When asked directly (e.g. "audit persona consistency", "check persona files for drift")
- When a new persona has just been created via `/agents`
- When an issue is raised requesting it

## Background — ADR-0003 transition

Per [ADR-0003](../docs/adr/0003-skill-based-persona-structure.md), persona files are migrating from carrying inline copies of common sections to carrying short pointers to canonical Layer C references in `references/`. The migration is staged across multiple PRs (#56 architect pilot, #57 per-persona roll-out).

During the transition, persona files exist in one of two states:

- **Migrated** — persona file contains a pointer to the canonical reference (e.g. links to `references/teammate-communication.md`).
- **Pre-migration** — persona file still has the old inline text and no pointer.

The audit handles both states. **A pre-migration persona is not a drift finding** — it is "awaiting Stage 3 migration".

## How to Run

1. **Read the reference**: `~/.claude/agents/common-sections-reference.md` lists each common section and its canonical Layer C reference (e.g. `references/teammate-communication.md`), plus the personas that should and should not have it.

2. **Read identity data**: `~/sandboxes/lucos_agent/personas.json` provides the persona-specific values (`bot_name`, `bot_user_id`, etc.) for cross-checking.

3. **Read each persona file**: `~/.claude/agents/lucos-*.md` (excluding `common-sections-reference.md` and any other non-persona file). Also read `~/.claude/agents/coordinator-persona.md` — the coordinator is not matched by the `lucos-*.md` glob but it has its own version of some sections.

4. **For each common section in the reference, check each persona file:**
   - **(a) Migrated check** — does the persona file contain a pointer to the canonical reference (e.g. mentions `references/teammate-communication.md`)? If yes: section is OK, skip to the next section.
   - **(b) Pre-migration check** — does the persona file contain the old inline text (without the pointer)? If yes: this is **not drift** — it is awaiting Stage 3 migration. Note it in the report under "personas awaiting migration" but do not modify the file. Pre-migration personas are tracked under [issue #57](https://github.com/lucas42/lucos_claude_config/issues/57) and will be migrated one per PR.
   - **(c) Missing check** — neither the pointer nor inline text is present? **This is a real finding.** A persona is missing a required common section entirely. Add the appropriate pointer (preferred — match the post-migration shape) and report.
   - **(d) Exclusion check** — `common-sections-reference.md` notes which personas should NOT have a given section (e.g. the coordinator does not have `Label Workflow` or `Committing ~/.claude Changes`). Respect those exclusions; do not flag absence as drift.

5. **Persona-specific additions** — personas may add their own sections, decision criteria, or notes. The reference's "Persona-specific additions (NOT drift)" section enumerates known intentional ones. New persona-specific content is allowed; do not remove it during audit.

6. **Check memory directory paths** — the canonical path is `/home/lucas.linux/.claude/agent-memory/{persona-name}/`. Flag and fix any that use a different base path (e.g. `/Users/lucas/`). This applies whether the persona is migrated or pre-migration.

7. **Check `~/.bash_aliases`** — verify that `~/.bash_aliases` contains a shell function for each persona file found in `~/.claude/agents/lucos-*.md`. Each persona should have a function (e.g. `lucos-architect() { _lucos_persona lucos-architect "$@"; }`) that calls the `_lucos_persona` helper. If any are missing, add them.

8. **Workflow file pointer spot-check** — for personas that respond to `"implement issue {url}"` (developer, architect, ux), check that they reference `agents/workflows/implement-issue.md` from their `Triggers` section. For personas the coordinator consults inline (architect, developer, security, sre, ux), check that they reference `agents/workflows/inline-triage-consultation.md`. Missing references on a migrated persona are real findings; pre-migration personas are exempt.

9. **Report findings** — group findings into:
   - **Migrated personas with real drift** (missing references, wrong memory path, missing workflow pointers) — fix and commit.
   - **Pre-migration personas awaiting Stage 3** — list with issue #57 cross-reference; do NOT modify these files.
   - **Persona-specific additions confirmed** — for the audit log, just so the report is honest about what was preserved.

## What counts as drift, and what doesn't

**Drift (a real finding, fix during audit):**

- A migrated persona is missing the pointer to a required Layer C reference.
- The wrong memory directory path (`/Users/lucas/...` instead of `/home/lucas.linux/...`).
- A migrated persona has BOTH the inline text AND the pointer (it should be one or the other; the pointer is preferred and the inline text should be removed).
- A persona's GitHub identity references the wrong app name (`--app lucos-architect` written into the wrong persona).
- `~/.bash_aliases` missing a function for a persona file that exists.

**Not drift (do not modify):**

- A pre-migration persona that still has the old inline text. Tracked under #57.
- Persona-specific additions enumerated in `common-sections-reference.md`.
- Different ordering of sections within a persona file, as long as required sections are present.
- A persona that has a workflow trigger the audit doesn't yet know about — file an issue rather than removing it.

## After Fixing Drift

Commit all changes to the `~/.claude` repo (`lucas42/lucos_claude_config`) with a clear commit message listing which personas were updated and what was fixed. See [`references/agent-github-identity.md`](../references/agent-github-identity.md) for the commit-and-push pattern (use `--app lucos-system-administrator`).
