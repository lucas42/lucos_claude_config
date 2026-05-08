# Common Persona Sections Reference

This file defines, for each common section that appears across persona instruction files in `~/.claude/agents/`, the canonical Layer C reference the persona should point to.

It is used by **lucos-system-administrator** when running a persona consistency audit (see `agents/sysadmin-persona-audit.md`).

**This file is NOT loaded by any agent.** It exists purely as a reference for the audit process.

## Background — ADR-0003 structure

Per [ADR-0003](../docs/adr/0003-skill-based-persona-structure.md), persona files no longer carry inline text for these common sections. Instead they contain a short pointer to the corresponding Layer C reference in `references/`. The Layer C reference is the **single source of truth** for the convention; the audit checks that personas reference it correctly.

A persona file is **migrated** when it contains the pointer. It is **pre-migration** when it has the old inline text but no pointer. The audit handles both states; see `agents/sysadmin-persona-audit.md` for the procedure.

## Common sections and their canonical references

| Section | Canonical reference | Who should have the pointer | Notes |
|---|---|---|---|
| Teammate Communication | `references/teammate-communication.md` | All personas | The coordinator (`coordinator-persona.md`) has its own communication conventions and does NOT use this pointer. |
| GitHub & Git Identity (combines GitHub Interactions and Git Commit Identity) | `references/agent-github-identity.md` | All personas | Persona file should specify the persona's own `--app <name>` flag near the pointer. |
| Label Workflow | `references/label-workflow.md` | All personas EXCEPT the coordinator | The coordinator IS the label controller — it does NOT have this section. |
| Persistent Agent Memory | `references/agent-memory-conventions.md` | All personas | Persona file should add its own memory directory path (`~/.claude/agent-memory/<persona>/`) and any persona-specific examples of what's worth saving. |
| Committing ~/.claude Changes | included within `references/agent-github-identity.md` (under the heading "Committing `~/.claude` changes") | All personas EXCEPT the coordinator | The coordinator has its own `~/.claude` maintenance instructions. The code-reviewer's persona may add a note about `agent-memory/lucos-code-reviewer/reptiles.md` being intentionally gitignored — that is a persona-specific addition, not drift. |

## Persona-specific additions (NOT drift)

The following are intentional persona-specific sections or additions that are not in the references and must not be removed during audit:

- **lucos-code-reviewer** — "Reptile Facts" section, and a note in the `~/.claude` Changes section about gitignored `reptiles.md`.
- **lucos-security** — additional Dependabot/CodeQL alert handling step in its triage discovery flow.
- **lucos-architect** — `Strategic Priorities`, `Architectural Philosophy`, `Architectural Reviews`, `Code Contributions`, `lucOS Infrastructure Conventions`, and `Self-Verification` sections; pointer to `references/raising-follow-up-issues.md`.
- **lucos-developer** — testing conventions, "let's try it" bias, code-quality standards.
- **lucos-system-administrator** — backup/volume conventions, the `agents/sysadmin-persona-audit.md` and `agents/sysadmin-ops-checks.md` pointers.
- **lucos-site-reliability** — incident reporting, ops-check pointer to `agents/sre-ops-checks.md`, CircleCI API pointer to `agents/sre-circleci-api.md`.
- **lucos-ux** — accessibility, copywriting, frontend-led work conventions.

These are the persona's own value-add — they layer on top of the shared references, they don't replace them.

## Workflow files (`agents/workflows/`)

ADR-0003 also introduced workflow files (Layer B) — step-by-step procedures loaded by the agent at the start of a workflow. These are referenced from the persona file's `Triggers` section:

- `agents/workflows/implement-issue.md` — for the `"implement issue {url}"` trigger. Used by personas that implement issues (developer, architect, ux).
- `agents/workflows/inline-triage-consultation.md` — for inline consultation by the coordinator. Used by personas the coordinator consults during triage (architect, developer, security, sre, ux).

The audit can spot-check that personas which respond to these triggers contain pointers to the appropriate workflow files. See `agents/sysadmin-persona-audit.md`.

## Memory directory paths

The canonical persistent-memory directory path is `/home/lucas.linux/.claude/agent-memory/<persona>/`. Flag and fix any persona that uses a different base path (e.g. `/Users/lucas/`).
