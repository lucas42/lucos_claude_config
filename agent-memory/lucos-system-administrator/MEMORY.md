# lucos-system-administrator Memory

## GitHub App commit attribution (avatar display)

For commits to show a GitHub App's custom avatar, the git committer email must use the **bot user ID**, not the App ID. These are different numbers. Using App ID gives a grey ghost avatar.

Format: `{bot_user_id}+{bot_name}@users.noreply.github.com`

**Canonical source of truth**: `~/sandboxes/lucos_agent/personas.json` — contains all per-persona identity data (`bot_user_id`, `bot_name`, `app_id`, `installation_id`, `pem_var`). Do not duplicate this data in memory files.

Note: the lucos-code-reviewer commit email uses the login `lucos-code-reviewer[bot]` (lowercase) even though the display name is `lucOS Code Reviewer[bot]` (mixed case).

Get user ID via: `curl -s 'https://api.github.com/users/lucos-agent%5Bbot%5D' | jq .id`

Always use `git -c user.name="..." -c user.email="..."` on the commit command itself — never `git config` which would affect all subsequent commits.

Current VM git config is correct (fixed 2026-02-27). `lima.yaml` in `lucos_agent_coding_sandbox` updated to match.

## Claude Code permissions: correct settings.json format

The correct key for bypassing permission prompts is `permissions.defaultMode`, NOT the top-level `dangerouslySkipPermissions`. The latter is silently ignored.

```json
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```

`bypassPermissions` is appropriate for this VM (isolated Lima sandbox, no host mounts, trivial recovery). Config lives in `~/.claude/settings.json`, tracked in `lucos_claude_config`. The `setup-repos.sh` in `lucos_agent_coding_sandbox` clones that repo into `~/.claude` so any fresh VM gets the correct setting automatically.

Wildcard allow rules (useful reference if ever dropping back to `default` mode):
- `Bash(git *)` — all git commands
- `Bash(gh *)` — all gh commands
- `Bash(docker *)` — all docker commands
- `Bash` — all bash (no parens = matches everything, equivalent to bypassPermissions for Bash only)

The `settings.local.json` at `/home/lucas.linux/sandboxes/.claude/settings.local.json` accumulated ~55 hyper-specific entries because the bypass setting was broken. Cleared to empty allow array (2026-02-28).

## GitHub App permissions: lucos-system-administrator

The `lucos-system-administrator` app has `pull_requests: write` (upgraded 2026-03-01, tracked in lucos_claude_config#1). It CAN:
- Post comments on PR threads (`POST /issues/{id}/comments` when issue is a PR)
- Post PR reviews (`POST /pulls/{id}/reviews`)
- Post to regular issue comment threads

Previously `pull_requests: read` only, which silently blocked PR thread comments despite having `issues: write`. Verified working after the permission upgrade.
