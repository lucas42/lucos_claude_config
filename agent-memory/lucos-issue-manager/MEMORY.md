# Agent Memory - lucos-issue-manager

## Repo-specific notes

See [repo-notes.md](repo-notes.md) for per-repo conventions and context.

## GitHub API quirks

- zsh does not support `labels[]=foo` syntax on the command line; always use `--input` with a JSON file for label operations
- When using `--app lucos_issue_manager` as the first argument to `gh-as-agent`, all other arguments are passed through to `gh api`
- `lucos-issue-manager` app does NOT have repo contents/push permissions -- cannot write files via Contents API or git push. Use the default `lucos-agent` app for file commits when needed.

## Label documentation

- Canonical label docs live at `docs/labels.md` in the `lucas42/lucos` repo

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

`owner:` labels indicate who should look next: `owner:lucas42`, `owner:lucos-architect`, `owner:lucos-system-administrator`, `owner:lucos-site-reliability`, `owner:lucos-security`. These exist across 9 repos as of 2026-03-02.

See [label-colours.md](label-colours.md) for full colour scheme.
