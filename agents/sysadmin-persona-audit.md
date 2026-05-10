# Persona Consistency Audit Procedure

This file is read by `lucos-system-administrator` when running a persona consistency audit.

## When to Run

- When asked directly (e.g. "audit persona consistency", "check persona files for drift")
- When a new persona has just been created via `/agents`
- When an issue is raised requesting it

## Background — ADR-0003 structure

Per [ADR-0003](../docs/adr/0003-skill-based-persona-structure.md), persona files carry short pointers to canonical Layer C references in `references/`, not inline copies of the conventions. The migration to this structure completed in May 2026 (Stages 1–4: PRs #54, #56, #57, #59-#68 across the seven personas, plus the Stage 4 tidy in #69 — see [`docs/agent-structure.md`](../docs/agent-structure.md) for the end-to-end model).

A persona file should be in the **migrated state**: each common section is a pointer (e.g. links to `references/teammate-communication.md`), not inline text. A persona that still carries inline text without the pointer is a real audit finding.

## How to Run

1. **Read the reference**: `~/.claude/agents/common-sections-reference.md` lists each common section and its canonical Layer C reference (e.g. `references/teammate-communication.md`), plus the personas that should and should not have it.

2. **Read identity data**: `~/sandboxes/lucos_agent/personas.json` provides the persona-specific values (`bot_name`, `bot_user_id`, etc.) for cross-checking.

3. **Read each persona file**: `~/.claude/agents/lucos-*.md` (excluding `common-sections-reference.md` and any other non-persona file). Also read `~/.claude/agents/coordinator-persona.md` — the coordinator is not matched by the `lucos-*.md` glob but it has its own version of some sections.

4. **For each common section in the reference, check each persona file:**
   - **(a) Pointer present** — does the persona file contain a pointer to the canonical reference? If yes: section is OK, skip to the next section.
   - **(b) Inline text without pointer** — does the persona file still carry the old inline text? **This is a real finding.** Replace the inline text with the canonical pointer (matching the migrated shape — see other personas for examples).
   - **(c) Both inline text AND pointer** — also a real finding. Remove the inline text; the pointer is the single source of truth.
   - **(d) Missing entirely** — neither pointer nor inline text. **Real finding.** Add the appropriate pointer.
   - **(e) Exclusion check** — `common-sections-reference.md` notes which personas should NOT have a given section (e.g. the coordinator does not have `Label Workflow`, `Scope of Work`, or `Committing ~/.claude Changes`). Respect those exclusions; do not flag absence as drift.

5. **Persona-specific additions** — personas may add their own sections, decision criteria, or notes. The reference's "Persona-specific additions (NOT drift)" section enumerates known intentional ones. New persona-specific content is allowed; do not remove it during audit.

6. **Check memory directory paths** — the canonical path is `/home/lucas.linux/.claude/agent-memory/{persona-name}/`. Flag and fix any that use a different base path (e.g. `/Users/lucas/`).

7. **Check `~/.bash_aliases`** — verify that `~/.bash_aliases` contains a shell function for each persona file found in `~/.claude/agents/lucos-*.md`. Each persona should have a function (e.g. `lucos-architect() { _lucos_persona lucos-architect "$@"; }`) that calls the `_lucos_persona` helper. If any are missing, add them.

8. **Workflow file pointer spot-check** — for personas that respond to `"implement issue {url}"` (developer, architect, ux, security, site-reliability, system-administrator), check that they reference `agents/workflows/implement-issue.md` from their `Triggers` section. For personas the coordinator consults inline (architect, developer, security, sre, sysadmin, ux), check that they reference `agents/workflows/inline-triage-consultation.md`. For lucos-code-reviewer, check it references `agents/workflows/review-pr.md`. Missing references are real findings.

9. **Report findings** — group findings into:
   - **Drift fixed** (missing/wrong pointers, wrong memory path, missing workflow pointers, duplicated inline text + pointer) — fix and commit.
   - **Persona-specific additions confirmed** — for the audit log, just so the report is honest about what was preserved.

## What counts as drift, and what doesn't

**Drift (a real finding, fix during audit):**

- A persona is missing the pointer to a required Layer C reference, or still has the old inline text.
- The wrong memory directory path (`/Users/lucas/...` instead of `/home/lucas.linux/...`).
- A persona has BOTH the inline text AND the pointer (it should be one or the other; the pointer is preferred and the inline text should be removed).
- A persona's GitHub identity references the wrong app name (`--app lucos-architect` written into the wrong persona).
- `~/.bash_aliases` missing a function for a persona file that exists.

**Not drift (do not modify):**

- Persona-specific additions enumerated in `common-sections-reference.md`.
- Different ordering of sections within a persona file, as long as required sections are present.
- A persona that has a workflow trigger the audit doesn't yet know about — file an issue rather than removing it.

## After Fixing Drift

Commit all changes to the `~/.claude` repo (`lucas42/lucos_claude_config`) with a clear commit message listing which personas were updated and what was fixed. See [`references/agent-github-identity.md`](../references/agent-github-identity.md) for the commit-and-push pattern (use `--app lucos-system-administrator`).
