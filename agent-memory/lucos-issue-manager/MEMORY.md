# Agent Memory - lucos-issue-manager

## Repo-specific notes

See [repo-notes.md](repo-notes.md) for per-repo conventions and context.

## GitHub API

- Pass body text and other fields inline using `-f key=value` — no need to write payload files
- When using `--app lucos-issue-manager` as the first argument to `gh-as-agent`, all other arguments are passed through to `gh api`
- `lucos-issue-manager` app has read & write access to repo contents -- can write files via Contents API and git push

## Process documentation

- lucos-issue-manager is responsible for maintaining process documentation (labels docs, workflow docs, triage process docs, etc.)
- Canonical label docs live at `docs/labels.md` in the `lucas42/lucos` repo (see also Label documentation section below)
- When process or workflow changes are agreed, update the relevant docs as part of the same piece of work

## Label documentation

- Canonical label docs live at `docs/labels.md` in the `lucas42/lucos` repo (also referenced in Process documentation section above)

## Label conventions

- `agent-approved` and `needs-refining` are created by this agent when they don't already exist in a repo
- Always check for existing labels before creating them to avoid duplicates
- Always set a meaningful colour when creating labels -- see [label-colours.md](label-colours.md) for the canonical colour scheme
- `agent-approved` = `0e8a16` (green), `needs-refining` = `d93f0b` (orange)
- User `lucas42` has explicitly requested consistent label colours across all repos

## Triage labels

### Status labels
- `status:ideation` -- goal/scope still vague; park until relevant (used with `needs-refining`)
- `status:needs-design` -- goal clear but needs implementation detail from an agent (used with `needs-refining`)
- `status:awaiting-decision` -- options discussed, waiting for lucas42 to pick one (used with `needs-refining`)
- `status:blocked` -- well-defined but blocked by another issue (used with `agent-approved`)

### Owner labels
`owner:` labels indicate who should look next. Used with both `needs-refining` (review) and `agent-approved` (implementation).
- `owner:lucas42`, `owner:lucos-architect`, `owner:lucos-system-administrator`, `owner:lucos-site-reliability`, `owner:lucos-security`, `owner:lucos-developer`

### Priority labels
- `priority:high` (red), `priority:medium` (yellow), `priority:low` (light blue)
- No priority label = not yet prioritised (distinct from medium)
- Set during triage when marking agent-approved

### Implementation assignment (introduced 2026-03-03)
When marking `agent-approved`, also assign an `owner:*` label for implementation:
- Default: `owner:lucos-developer`
- Purely infra: `owner:lucos-system-administrator`
- Purely monitoring/logging/pipelines: `owner:lucos-site-reliability`
- Incident management (response, reporting, post-mortems, tracking): `owner:lucos-site-reliability`
- Purely security: `owner:lucos-security`
- Workflow/process docs: `owner:lucos-issue-manager`
- Mixed work: `owner:lucos-developer` (ensure specialist reviewed first)

## Review capability (introduced 2026-03-05)

- lucos-issue-manager responds to both "triage your issues" and "review your issues"
- Review covers `needs-refining` issues assigned via `owner:lucos-issue-manager` -- typically workflow, process docs, issue conventions
- Uses `get-issues-for-persona --review lucos-issue-manager` for discovery
- Participates in Phase 2 of /routine skill (alongside specialist agents)
- lucos-developer also participates in Phase 2 review for design-phase input

All labels exist across 16 repos. See [label-colours.md](label-colours.md) for full colour scheme.

## Specialist follow-up routing (introduced 2026-03-03)

Two domains get specialist follow-up after the primary owner finishes, before `agent-approved`:

- **SRE**: Issues touching monitoring, logging, observability, reliability, or incident management (response, reporting, post-mortems, tracking) get re-routed to `owner:lucos-site-reliability`
- **Security**: Issues touching authentication, authorisation, data protection, secret management, or other security topics get re-routed to `owner:lucos-security`

Both also apply mid-lifecycle if concerns are raised in comments after initial triage.
Examples: pici#2 (monitoring, primary owner sysadmin), lucos_monitoring#26 (monitoring endpoint, primary owner architect)

## Common pitfalls

- When creating multiple sub-tickets that reference each other, the issue numbers are not known until each issue is created. Write bodies with placeholder references, then update them after all issues exist. Alternatively, create all issues first, note the actual numbers, then patch the bodies.

## Issue closure policy

- lucos-issue-manager IS allowed to close issues directly when confident no further work is needed
- Examples: issue superseded by other issues, split into sub-tickets, agreed in discussion to be obsolete
- Use `state_reason="completed"` when the goal was achieved (e.g. via sub-tickets), `"not_planned"` when discarding
- Always leave a brief comment explaining why before closing
- Remove `needs-refining`, `status:*`, and `owner:*` labels before closing
- Granted by lucas42 on 2026-03-03
