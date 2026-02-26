# Agent Memory - lucos-issue-manager

## Repo-specific notes

See [repo-notes.md](repo-notes.md) for per-repo conventions and context.

## GitHub API quirks

- zsh does not support `labels[]=foo` syntax on the command line; always use `--input` with a JSON file for label operations
- When using `--app lucos_issue_manager` as the first argument to `gh-as-agent`, all other arguments are passed through to `gh api`

## Label conventions

- `agent-approved` and `needs-refining` are created by this agent when they don't already exist in a repo
- Always check for existing labels before creating them to avoid duplicates
