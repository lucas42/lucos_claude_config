# Agent file structure (the three-layer model)

This document describes the file layout for agent personas, workflows, and shared references in `~/.claude/`. The model was established by [ADR-0003](adr/0003-skill-based-persona-structure.md) and rolled out across all seven `lucos-*` personas in May 2026 (Stages 1–4: PRs #54, #56, #57, plus the per-persona PRs in #59-#68 and the Stage 4 tidy in #69).

It exists so that future contributors (human or agent) know where new content belongs without having to reverse-engineer the convention from the existing files.

## The three layers

```
~/.claude/
├── agents/
│   ├── <persona>.md                    Layer A: identity + triggers (always loaded)
│   ├── workflows/
│   │   └── <workflow>.md               Layer B: step-by-step procedure (loaded on trigger)
│   └── …                               Persona-specific extensions (e.g. ops-checks files,
│                                       audit procedures, judgement criteria)
└── references/
    └── <topic>.md                      Layer C: cross-cutting conventions (loaded on first need)
```

### Layer A — Persona files (always loaded)

**Location:** `agents/<persona>.md`
**Target size:** ≤150 lines (excluding the appended `MEMORY.md`, which the harness loads automatically).

A persona file is loaded into the system prompt the moment a teammate is spawned and stays loaded for the life of the session. Everything in it shapes every response — so it should contain only what genuinely needs to be in the system prompt at all times.

Belongs in Layer A:

- **Frontmatter** — `name`, `description`, `model`, `color`, `memory`.
- **Identity** — voice, values, personality, backstory link.
- **Decision criteria the persona applies frequently** — heuristics that shape every response, not just one workflow. Examples: the architect's "ask why before how", the reviewer's review heuristics, the developer's "let's try it and see".
- **Triggers section** — short list mapping recognised message patterns (e.g. `"implement issue {url}"`) to the workflow file the agent should read before acting.
- **Pointers to Layer C references** — short links to the canonical sources for SendMessage rules, GitHub identity, label workflow, memory conventions, scope of work. Each pointer adds the persona-specific values where relevant (e.g. `--app <persona>` for GitHub identity, persona-specific memory directory).
- **Persona-specific tone or relationship notes.**
- **Memory pointer + the appended `MEMORY.md` block.**

Does NOT belong in Layer A:

- Step-by-step procedures for individual triggers — those go in Layer B.
- Cross-cutting conventions duplicated across multiple personas — those go in Layer C.
- Reference data like API patterns, file paths, or schemas — those go in Layer C (or a persona-specific extension file under `agents/` if only one persona uses them).

### Layer B — Workflow files (loaded on trigger)

**Location:** `agents/workflows/<workflow-name>.md`
**Target size:** ≤200 lines per file.

A workflow file is read by the agent **at the start of the corresponding trigger**, on every invocation. The persona file's Triggers section names the file path so the agent knows what to read.

Belongs in Layer B:

- Step-by-step procedure for one named workflow (e.g. `implement-issue.md`, `review-pr.md`, `inline-triage-consultation.md`).
- Cross-references to Layer C shared references where relevant.
- Persona-specific extensions, named at the bottom of the workflow file as guidance for the persona files that need to layer on top.

A workflow file may be **shared by multiple personas** — `implement-issue.md` is currently shared by all six implementing personas, with each layering its own extensions. Sharing the workflow is the point: it's the single source of truth for "how implement-issue works", and per-persona extensions live in the persona file (in a section named, e.g., "Working on Issues — SRE Extensions") rather than being re-stated in copies of the workflow.

Some workflow-shaped content lives directly under `agents/` rather than `agents/workflows/` because it is owned by a single persona's regular operations:

- `agents/sre-ops-checks.md`, `agents/security-ops-checks.md`, `agents/sysadmin-ops-checks.md` — ops-check task lists, one per persona, loaded by the `"run your ops checks"` trigger.
- `agents/sre-circleci-api.md` — SRE CircleCI reference, loaded when investigating CI.
- `agents/sysadmin-persona-audit.md` — sysadmin persona-consistency audit procedure, loaded by the `"audit persona consistency"` trigger.
- `agents/code-reviewer-stuck-pr-guide.md` — stuck-PR criteria reference for the reviewer.
- `agents/common-sections-reference.md` — audit reference (not loaded by any agent; read by the audit procedure).

Convention: if a procedure is shared across multiple personas, it goes in `agents/workflows/`. If it's owned by exactly one persona's regular operations, it can live directly under `agents/` with a `<persona-prefix>-<name>.md` filename.

### Layer C — Shared instruction references (loaded on first need)

**Location:** `references/<topic>.md`
**Target size:** ≤150 lines per file (most are smaller — many are <80 lines).

These are the cross-cutting conventions and reference data that any persona or workflow might need. They are loaded by the agent the first time a workflow tells it to read one, or when `CLAUDE.md` points to one for global conventions.

Belongs in Layer C:

- **Conventions duplicated across most/all personas:** SendMessage rules, GitHub App identity wrappers, label workflow, memory conventions, scope-of-work / dispatch contract, committing `~/.claude` changes.
- **Technical references that aren't persona-specific:** docker conventions, info-endpoint spec, network topology, monitoring/Loganne, SSH production conventions, etc.
- **Procedures that span multiple agents:** issue creation, audit-finding handling, lucos-repos API.

A new Layer C reference file should:

1. Have a clear single topic in its filename (e.g. `agent-memory-conventions.md`, not `misc-conventions.md`).
2. Be added to the Reference Files table in `~/.claude/CLAUDE.md` if it's a general convention.
3. Be linked from each persona or workflow file that needs it.

## How to add new content

### Adding a new persona

1. Create `agents/<persona-name>.md` modelled on an existing persona (start from `lucos-developer.md` or `lucos-architect.md` — they're the cleanest examples).
2. Include pointers to all Layer C references that apply (typically: teammate-communication, agent-github-identity, label-workflow, agent-memory-conventions, scope-of-work).
3. List triggers in the Triggers section, naming the workflow files the persona will read.
4. Run the persona-consistency audit (`lucos-system-administrator` does this — `agents/sysadmin-persona-audit.md`) to catch any drift before merging.

### Adding a new workflow

1. Create `agents/workflows/<workflow-name>.md`.
2. Open with one paragraph naming the trigger and the personas that respond to it.
3. Number the steps. Cross-reference Layer C where relevant.
4. Add a "Persona-specific extensions" section at the bottom listing what each persona may layer on top, so persona-file authors know where to add their extensions.
5. Update each persona's Triggers section to point to the new workflow file.

### Adding a new shared reference

1. Create `references/<topic>.md`.
2. Lead with a one-paragraph statement of what the reference covers and which personas it applies to.
3. Keep it focused on the one topic — if you find yourself wanting to write a second topic, make it a separate file.
4. Add it to the Reference Files table in `CLAUDE.md` if it's a general convention.
5. Update the personas, workflows, or other references that should now point to it.

## Why this structure

ADR-0001 established that long instruction files suffer from attention degradation — instructions deep in the file are progressively more likely to be silently skipped. ADR-0003 generalised the ops-check extraction pattern from ADR-0001 to the whole persona system: keep the always-loaded surface small (Layer A), put procedural content where it can be loaded only when relevant (Layer B), and keep cross-cutting conventions in one canonical place each (Layer C).

The end state has three measurable wins:

- **Persona files are smaller** (ranging from ~100 to ~200 lines now, down from the 250–380-line range pre-migration). Less attention degradation per session.
- **Conventions live in one place each.** Updating the SendMessage rule means editing one file (`references/teammate-communication.md`), not seven persona files.
- **Adding a new persona is cheap** — it's identity plus pointers, not a 300-line copy-paste of conventions.

For full context on why the change was made, see ADR-0003: `docs/adr/0003-skill-based-persona-structure.md`.
