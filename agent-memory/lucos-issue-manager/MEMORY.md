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

## Triage labels (introduced 2026-03-02)

Three `status:` labels classify *why* an issue with `needs-refining` is blocked:
- `status:ideation` -- goal/scope still vague; park until relevant
- `status:needs-design` -- goal clear but needs implementation detail from an agent
- `status:awaiting-decision` -- options discussed, waiting for lucas42 to pick one (highest priority for lucas42)

`owner:` labels indicate who should look next: `owner:lucas42`, `owner:lucos-architect`, `owner:lucos-system-administrator`, `owner:lucos-site-reliability`, `owner:lucos-security`. These exist across 11 repos as of 2026-03-02 (added lucos_deploy_orb and lucos_media_metadata_manager).

See [label-colours.md](label-colours.md) for full colour scheme.

## Specialist follow-up routing (introduced 2026-03-03)

Two domains get specialist follow-up after the primary owner finishes, before `agent-approved`:

- **SRE**: Issues touching monitoring, logging, observability, or reliability get re-routed to `owner:lucos-site-reliability`
- **Security**: Issues touching authentication, authorisation, data protection, secret management, or other security topics get re-routed to `owner:lucos-security`

Both also apply mid-lifecycle if concerns are raised in comments after initial triage.
Examples: pici#2 (monitoring, primary owner sysadmin), lucos_monitoring#26 (monitoring endpoint, primary owner architect)

## Issue closure policy

- lucos-issue-manager IS allowed to close issues directly when confident no further work is needed
- Examples: issue superseded by other issues, split into sub-tickets, agreed in discussion to be obsolete
- Use `state_reason="completed"` when the goal was achieved (e.g. via sub-tickets), `"not_planned"` when discarding
- Always leave a brief comment explaining why before closing
- Remove `needs-refining`, `status:*`, and `owner:*` labels before closing
- Granted by lucas42 on 2026-03-03
