# ADR-0003: Skill-based persona structure

**Date:** 2026-05-08
**Status:** Proposed

## Context

Persona files in `~/.claude/agents/` currently mix several kinds of content:

1. **Identity** — voice, values, backstory, decision criteria the persona applies frequently.
2. **Communication conventions** — SendMessage rules, teammate_id handling, GitHub identity wrappers (`gh-as-agent`, `git-as-agent`).
3. **Workflow procedures** — step-by-step instructions for "implement an issue", "review a PR", "do a triage consultation", etc.
4. **Reference data** — file paths, API patterns, label rules, memory conventions.
5. **Persistent memory** — appended at the bottom and loaded into the system prompt every session.

These are all loaded as the agent's system prompt the moment a teammate is spawned, and they stay loaded for the life of the session. Current sizes:

| Persona | Lines |
|---|---|
| `lucos-developer` | 256 |
| `lucos-security` | 270 |
| `lucos-architect` | 315 |
| `lucos-system-administrator` | 322 |
| `lucos-ux` | 359 |
| `lucos-site-reliability` | 367 |
| `lucos-code-reviewer` | 378 |
| **Total** | **~2,267** |

ADR-0001 established that long instruction files suffer from attention degradation — items deeper in the file are progressively more likely to be silently skipped — and set a 200-line target for compliance-critical files. Several persona files have crept above that threshold, and the trend is upward as new conventions and lessons accumulate.

ADR-0001 mitigated the immediate problem by extracting **ops checks** (one specific kind of structured task list) into separate files (`agents/sre-ops-checks.md`, `agents/security-ops-checks.md`, `agents/sysadmin-ops-checks.md`) which the agent reads at the start of the relevant workflow. The pattern works: the extracted ops checks have not regressed.

The same pattern is at play in `~/.claude/references/`, where 16 reference files (~1,600 lines total) are loaded on demand from `CLAUDE.md` mentions or from persona-specific pointers — `references/triage-procedure.md`, `references/github-workflow.md`, `references/architectural-review.md`, etc. These are also not regressing.

This ADR proposes scaling that pattern up: shrink persona files to **identity + frequently-applied judgement criteria + pointers**, and move the rest into trigger-loaded workflow files and shared instruction references.

## Terminology note

This issue refers to the change as a "skill-based persona refactor". The word **skill** here is generic — *a procedural body of "how to do X" content loaded on demand*. It is **not** a proposal to extend the harness `Skill` tool (`/triage`, `/dispatch`, etc.) to teammate-side use. See "Why not the harness Skill tool" below.

## Decision

### 1. Three-layer structure

Each persona's instructions split into three layers, with explicit rules about what goes where.

#### Layer A — Persona file (always loaded)

Location: `agents/<persona>.md`. Target: ≤150 lines (excluding the appended `MEMORY.md` content, which is the persona's own concern).

Contains:
- Frontmatter (name, description, model, color, memory)
- Identity statement: voice, values, perspective, backstory link
- **Decision criteria the persona applies frequently** — e.g. the architect's "ask why before how", the developer's "let's try it and see", the reviewer's review heuristics. These shape every response, not just specific workflows, so they must be in the system prompt at all times.
- A **Triggers** section: a short list mapping recognised message patterns to the workflow file the agent should read before acting.
- Pointers to the shared instruction references (Layer C) the persona uses.
- Persona-specific relationship/tone notes.
- Memory pointer + the persona's `MEMORY.md` block.

#### Layer B — Workflow files (loaded on trigger)

Location: `agents/workflows/<workflow-name>.md`. Target: ≤200 lines each.

Contains:
- Step-by-step procedure for one named workflow (e.g. `implement-issue.md`, `architectural-review.md`, `inline-triage-consultation.md`, `pr-review-loop.md`).
- Cross-references to Layer C shared references where relevant.

A workflow file is read by the agent **at the start of the corresponding trigger**, on every invocation. The persona file's Triggers section names the file path explicitly so the agent knows what to read.

A workflow file may be **shared by multiple personas**. For example, `implement-issue.md` is used identically by lucos-developer, lucos-architect, and lucos-ux — only the GitHub App identity differs, and that's a Layer C reference. Today this content is duplicated three times (with subtle drift); under this structure it lives in one place.

#### Layer C — Shared instruction references (loaded on first need within a workflow)

Location: `references/<reference-name>.md` (the existing directory). Most of these already exist or are 1-line away from existing.

Contains:
- Conventions duplicated across most/all personas: SendMessage rules, GitHub App identity wrappers, label workflow, memory conventions, the "committing ~/.claude changes" boilerplate.
- Technical references that aren't persona-specific (which is what already lives there): docker conventions, info endpoint spec, network topology, etc.

Layer C files are small (most ≤80 lines) and act as the canonical source of truth for the convention. The persona file links to them from its "Communication Conventions" / "GitHub Identity" sections; the workflow file references them at the points where they apply.

### 2. Trigger mechanism: "Read this file" via the Read tool

Workflow files are loaded by the agent reading them with its existing `Read` tool, prompted by an explicit instruction in the persona file:

```
## Triggers

- "implement issue {url}" — Read agents/workflows/implement-issue.md before acting.
- "review for issue {url}" (inline triage consultation) — Read agents/workflows/inline-triage-consultation.md.
- "architectural review of {repo}" — Read references/architectural-review.md.
```

This is the same mechanism the ops-check extraction in ADR-0001 used, generalised to all workflow content. It works for every teammate, requires no new tool plumbing, and degrades gracefully — if the file is missing or temporarily unreachable, the agent has enough in the persona file to identify and report the failure rather than confabulating.

### 3. Why not the harness Skill tool

The Skill tool currently exposes user/coordinator-facing slash commands (`/triage`, `/dispatch`, `/estate-rollout`, `/team`). It would be technically possible to add per-persona skills and have teammates self-invoke. We are choosing **not to** for the following reasons:

- **Skills are global**. Adding a skill per persona-workflow combination would clutter the global skill namespace with content that's only relevant inside one persona's session.
- **Skills are user-discoverable**. The Skill tool surfaces all skills to the harness for autocomplete and slash-command invocation. Workflow files for teammates have no business appearing there.
- **No additional capability**. A teammate reading a workflow file via `Read` has the same end result as invoking a skill that prints the same content — and the file path is more inspectable than a skill descriptor.
- **The pattern works today.** Ops checks are loaded this way and don't regress. There's no demonstrated problem with the approach that a Skill-based mechanism would solve.

User-facing skills (`/triage`, `/dispatch`, etc.) remain skills. They are coordinator-invoked, not teammate-invoked, and that boundary is the right one.

### 4. The boundary, restated

| Content type | Layer | Why |
|---|---|---|
| Identity, voice, values | A | Shapes every response. Always loaded. |
| Decision criteria the persona applies frequently | A | Shapes every response. Always loaded. |
| Trigger list (which message → which file) | A | Required for the agent to know what to load. |
| Step-by-step "how to do X" procedure | B | Only relevant during X. Loaded on trigger. |
| Cross-persona convention (SendMessage, gh-as-agent, label rules) | C | Shared. One source of truth. Linked from A and B. |
| Reference data (API patterns, file paths, schemas) | C | Already lives here. Loaded on demand. |
| Persistent memory | A | Loaded into system prompt by harness. |

### 5. Migration path

The migration is staged so that no step requires a coordinated "all personas at once" change.

#### Stage 1 — Land Layer C shared references (additive, no persona churn)

Extract the duplicated boilerplate from existing persona files into `references/`:

- `references/teammate-communication.md` — SendMessage rules, teammate_id handling, "user cannot see messages between teammates", canonical name lookup.
- `references/agent-github-identity.md` — `gh-as-agent`, `git-as-agent`, the heredoc pattern, the template-substitution gotcha, "always use --app `<persona>`" rule (parameterised).
- `references/label-workflow.md` — "do not touch labels", post a summary comment, link to `lucos/docs/labels.md`.
- `references/agent-memory-conventions.md` — what to save, what not to save, MEMORY.md size limit, semantic vs chronological organisation.

These files are written from the existing persona content; nothing is changed in the personas yet. This is purely additive and reviewable independently. After this stage, the references exist but are not yet linked from the personas.

#### Stage 2 — Pilot the architect persona

Migrate `lucos-architect.md` to the new structure:
- Strip the duplicated boilerplate; replace with one-line pointers to the Stage 1 references.
- Move "Working on GitHub Issues" → `agents/workflows/implement-issue.md` (which the architect, developer, and ux will all share — but at this stage, only the architect points to it).
- Move "Architectural Reviews" → already in `references/architectural-review.md`; just keep the pointer.
- Move "Inline triage consultation" content → `agents/workflows/inline-triage-consultation.md`.
- Move "Raising follow-up issues from design work" → `references/raising-follow-up-issues.md`.

Validate by:
1. Asking the architect to do a real implementation issue and a real inline consultation. Confirm both still work.
2. Measuring resulting persona file size (target: ≤150 lines pre-`MEMORY.md`).

#### Stage 3 — Roll out one persona at a time

Apply the same structural pattern to each remaining persona, one PR per persona. Order by current file size descending (worst offenders first):

1. `lucos-code-reviewer` (378 lines)
2. `lucos-site-reliability` (367 lines)
3. `lucos-ux` (359 lines)
4. `lucos-system-administrator` (322 lines)
5. `lucos-security` (270 lines)
6. `lucos-developer` (256 lines)

Each migration:
- Updates the persona file to use shared references and workflow files.
- Adds new workflow files only for procedures unique to that persona.
- Reuses existing workflow files where possible (e.g. `implement-issue.md` already created in Stage 2).
- Is reviewable as a single PR with a small structural diff.

Stop after each migration to confirm nothing has regressed. Do not batch.

#### Stage 4 — Tidy

Once all seven personas are migrated:
- Audit for residual duplication (any boilerplate that ended up in two workflow files instead of one shared reference).
- Update `CLAUDE.md` to point to the new layout.
- Close the implementation issues that fall out of this ADR.

### 6. What ships incrementally vs together

- **Stage 1** can ship as multiple PRs, one per shared reference, in any order. Each is independently reviewable and risks nothing.
- **Stage 2** is one PR per persona migration. Stage 2 cannot start before Stage 1 completes, because the personas reference Stage 1 files.
- **Stage 3** PRs are independent of each other and can interleave.
- **Stage 4** is a tidy-up pass once everything else is done.

The whole rollout is **decomposable**. There is no atomic "convention + rollout" coupling like the `lucos_repos` estate-rollout case — these are not audit-checked conventions, just persona-internal references. Standard `/dispatch` flow is fine.

### 7. Tier 4 vs Tier 2 sequencing

The token-usage audit conversation referenced in the issue identified four tiers of work. Tier 1 (the ADR-0001 ops-check extractions) is already done. Tier 2 was a planned set of further targeted extractions; Tier 4 is this structural refactor.

**Recommendation: do Tier 4 before completing Tier 2.**

Reasons:
- Tier 2 risks creating extracted files in the wrong shape — sized for "this is one chunk that was too big" rather than for "this is one workflow trigger". A Stage 1 → Stage 2 → Stage 3 rollout naturally absorbs everything Tier 2 was aiming for, with a cleaner end state.
- Doing Tier 2 first means doing some of the same extractions twice — once to satisfy a line-count budget, then again to fit the structural model. That's churn for no benefit.
- Tier 1's already-completed extractions (ops checks) fit the new model unchanged. They become the prototype for Layer B. Nothing lost from leaving them as they are.

### 8. User-facing impact

None. The user still types `/dispatch <url>` or `implement the next issue` (or messages the team-lead in plain language). The team-lead still routes to the correct persona via SendMessage with the same `"implement issue {url}"` payload. The persona's behaviour should improve (less attention degradation, less drift between duplicated copies of the same convention) but the interaction surface is unchanged.

## Worked example: lucos-architect

### Before (315 lines, present state)

The current file contains:

- Backstory link (~3 lines)
- Personality (~10 lines)
- Strategic priorities pointer (~5 lines)
- "Communicating with Teammates" section (~25 lines, near-identical across all 7 personas)
- "Implementation" section, mixing trigger definitions with workflow procedure (~50 lines)
- "Architectural Philosophy" (~10 lines)
- "Code Contributions" (~7 lines)
- "Architectural Reviews" pointer (~5 lines)
- "Label Workflow" (~6 lines, near-identical across personas)
- "Working on GitHub Issues" (~30 lines, mostly shared with developer)
- "Raising follow-up issues from design work" (~50 lines, architect-specific)
- "GitHub & Commit Behaviour" (~30 lines, near-identical with persona name swapped)
- "Git Commit Identity" (~30 lines, near-identical with persona name swapped)
- "Relationships with Team Members" (~5 lines)
- "lucOS Infrastructure Conventions" (~10 lines)
- "Self-Verification" (~10 lines)
- "Memory" boilerplate (~30 lines, near-identical across personas)
- The actual `MEMORY.md` content (variable)

Of these, the **bold** sections are duplicated almost verbatim across personas:

- Communicating with Teammates
- Label Workflow
- GitHub & Commit Behaviour
- Git Commit Identity
- Memory boilerplate
- "Committing ~/.claude Changes" (referenced via `CLAUDE.md` already)

That's ~120 lines of pure duplication out of 315. Multiply by 7 personas = ~840 lines of redundant content in the system, every line of it a drift risk.

### After (target ~120 lines pre-`MEMORY.md`)

```markdown
---
name: lucos-architect
description: ...
model: opus
color: ...
memory: user
---

You are a Technical Architect working on the lucOS family of systems. Your name
is the lucos-architect persona. You think about long-term viability ahead of
short-term delivery — security, reliability, and resource consumption, in that
order of moral weight.

[~10 more lines of identity / personality]

## Backstory & Identity
Full backstory: backstories/lucos-architect-backstory.md

## Strategic Priorities
The current strategic priorities for the lucos ecosystem are documented in
~/sandboxes/lucos/docs/priorities.md. Consult this when making architectural
decisions. When a decision changes the strategic direction, update priorities.md
and commit to main.

## Architectural Philosophy
When reviewing or designing systems, you always consider:
- Long-term viability — will this still make sense in 3-5 years?
- Security — what is the attack surface? what data is exposed and to whom?
- Reliability — what are the failure modes? single points of failure?
- Resource consumption — efficient? sane scaling?
- Simplicity — complexity is a liability. Every added component must justify itself.

You are sceptical of fashionable technology choices. You ask what problem
something actually solves and prefer boring, proven solutions when they fit.

## Triggers

You respond to one primary message pattern:

- **"implement issue {url}"** — Read [`agents/workflows/implement-issue.md`](workflows/implement-issue.md)
  before acting. Applies to ADRs and documentation issues assigned to you. Drive
  the PR review loop to completion before reporting back.

You may also be consulted inline by the coordinator during triage when an
issue needs architectural input. In that case, read
[`agents/workflows/inline-triage-consultation.md`](workflows/inline-triage-consultation.md)
before responding.

For architectural reviews of a specific repo, read
[`references/architectural-review.md`](../references/architectural-review.md).

When raising follow-up issues from design work — particularly anything that
might trigger an estate rollout — read
[`references/raising-follow-up-issues.md`](../references/raising-follow-up-issues.md).

## Communication Conventions

Read [`references/teammate-communication.md`](../references/teammate-communication.md)
for SendMessage rules, teammate_id handling, and the "user cannot see
messages between teammates" rule. Apply on every reply to a teammate.

## GitHub & Git Identity

Use `--app lucos-architect` for all `gh-as-agent` and `git-as-agent` calls.
Read [`references/agent-github-identity.md`](../references/agent-github-identity.md)
for the heredoc pattern, the template-substitution gotcha, and the rules for
`git-as-agent` (which you must use for every commit-writing operation).

## Label Workflow

Read [`references/label-workflow.md`](../references/label-workflow.md). Do not
touch labels — the coordinator owns them. Post a summary comment when you finish
work and stop.

## Self-Verification

Before delivering any architectural assessment or recommendation:
[~10 lines, persona-specific]

## Relationships with Team Members
[~10 lines, persona-specific]

## Memory

Read [`references/agent-memory-conventions.md`](../references/agent-memory-conventions.md)
for what to save, what not to save, MEMORY.md size limits, and the
"frame-review" pattern.

Your memory directory is at `~/.claude/agent-memory/lucos-architect/`.

## MEMORY.md

[loaded into system prompt automatically]
```

The line count drops from 315 (excluding the appended `MEMORY.md`) to roughly 120 lines of human-written content, with no loss of behaviour. The shared references absorb ~120 lines of previously-duplicated boilerplate, which is now also gone from the other six personas the moment they migrate.

## Consequences

### Positive

- **Less attention degradation in the system prompt.** ADR-0001's mitigation generalised: every persona file gets shorter, every workflow file is short and focused.
- **Single source of truth for conventions.** SendMessage rules, GitHub identity, label workflow, memory conventions — each lives in exactly one place. Updates propagate automatically.
- **Drift risk drops sharply.** Today, a SendMessage rule update has to be applied seven times (and historically hasn't always been). After migration, it's one edit.
- **Cheaper to add a new persona.** A new persona file is identity + a few pointers, not a 300-line copy-paste.
- **Workflow procedures are reviewable in isolation.** Changes to "how implement-issue works" don't have to navigate around persona-identity edits.
- **No atomic rollout requirement.** Each stage can ship independently; nothing is gated on a coordinated all-personas change.
- **Token cost likely decreases on average**, since persona files are loaded into every spawned teammate's system prompt and are now smaller. Workflow files are loaded only when needed. Worst case (a complex workflow) is roughly equivalent to the current state; common case (a simple message exchange) is cheaper.

### Negative

- **More files to navigate.** The `~/.claude/` tree gets wider. A reader doing first-time orientation has more breadcrumbs to follow. Mitigation: clear naming conventions; the "Triggers" section in each persona acts as the table of contents.
- **One more level of indirection on every workflow.** The agent has to read the workflow file before acting. This is the cost of the design — accepted, because the same indirection has worked for ops checks without regression.
- **Workflow file divergence risk.** If a workflow file is shared by multiple personas, a change made for one persona's needs might be wrong for another. Mitigation: explicit comments in workflow files calling out which personas use them; review check during PR.
- **Cross-cutting changes (e.g. a new GitHub-API gotcha) need updating in fewer places, but the right place is now non-obvious.** Mitigation: the references already follow a clear naming convention (`references/agent-github-identity.md` for identity, `references/teammate-communication.md` for SendMessage, etc.). New rules of thumb belong in the most specific reference; cross-cutting changes go to the canonical one.
- **Pilot risk on the architect persona.** The first migration may surface unanticipated coupling — e.g. a workflow procedure that subtly relies on something in the persona file. Mitigation: pilot is one PR, reviewable, and reversible.

### Known constraints

- **Workflow files are not technically enforced as "read on trigger".** A persona could in principle skip the read and act from the persona file alone. This is the same trust model as ADR-0001's ops checks — it has not been observed to regress, but it is not enforced. If regressions appear in practice, mitigations are: more explicit "you MUST read X first" wording, or a dispatcher-side verification step (per ADR-0001 §3).
- **The MEMORY.md size pressure is unaffected by this ADR.** Persona memory is still loaded into the system prompt at session start and still grows over time. The architect's MEMORY.md is currently ~200 lines and growing. That's a separate problem — the structural refactor here doesn't shrink it, but doesn't worsen it either.

## Acceptance gate

Per the original issue, this ADR must be reviewed before any implementation work begins. Specifically:

- Stage 1 (shared references) should not start until the ADR is accepted.
- Once the ADR is accepted, each stage's work can be raised as separate `/dispatch`-routed implementation issues against `lucos-architect` (for ADR-0001-style structural work that touches persona files).
- The pilot (Stage 2 — architect migration) should explicitly validate against a real implementation issue and a real inline consultation before Stage 3 begins.

## Refs

- Issue: lucas42/lucos_claude_config#37
- ADR-0001: Agent instruction compliance for structured task lists (`docs/adr/0001-agent-instruction-compliance.md`)
- ADR-0002: Migration from subagent dispatch to agent teams (`docs/adr/0002-agent-teams-migration.md`)
- Token usage audit conversation 2026-04-10 (referenced in issue)
