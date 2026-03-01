# lucos-system-administrator Memory

## GitHub App commit attribution (avatar display)

For commits to show a GitHub App's custom avatar, the git committer email must use the **bot user ID**, not the App ID. These are different numbers.

Format: `{USER_ID}+{app-name}[bot]@users.noreply.github.com`

| App | Bot name | Bot User ID | Correct commit email |
|---|---|---|---|
| lucos-agent | `lucos-agent[bot]` | 263775988 | `263775988+lucos-agent[bot]@users.noreply.github.com` |
| lucos-issue-manager | `lucos-issue-manager[bot]` | 264038870 | `264038870+lucos-issue-manager[bot]@users.noreply.github.com` |
| lucos-code-reviewer | `lucOS Code Reviewer[bot]` | 264151378 | `264151378+lucos-code-reviewer[bot]@users.noreply.github.com` |
| lucos-system-administrator | `lucos-system-administrator[bot]` | 264392982 | `264392982+lucos-system-administrator[bot]@users.noreply.github.com` |
| lucos-site-reliability | `lucos-site-reliability[bot]` | 264646982 | `264646982+lucos-site-reliability[bot]@users.noreply.github.com` |
| lucos-architect | `lucos-architect[bot]` | 264682300 | `264682300+lucos-architect[bot]@users.noreply.github.com` |

Note: the lucos-code-reviewer commit email uses the login `lucos-code-reviewer[bot]` (lowercase) even though the display name is `lucOS Code Reviewer[bot]` (mixed case).

Get user ID via: `curl -s 'https://api.github.com/users/lucos-agent%5Bbot%5D' | jq .id`

The App ID is only used for JWT authentication (in `get-token`). Using App ID in the email gives a grey ghost avatar.

Always use `git -c user.name="..." -c user.email="..."` on the commit command itself — never `git config` which would affect all subsequent commits.

Current VM git config is correct (fixed 2026-02-27). `lima.yaml` in `lucos_agent_coding_sandbox` updated to match.

See: `/home/lucas.linux/sandboxes/lucos_agent/CLAUDE.md` for full app details.

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

The `lucos-system-administrator` app has `pull_requests: read` (NOT write). This means it CANNOT:
- Post PR reviews (`POST /pulls/{id}/reviews`)
- Post comments on PR threads (`POST /issues/{id}/comments` when issue is a PR — needs `pull_requests: write` even though it has `issues: write`)

It CAN post to regular issue comment threads (non-PR issues).

Tracked in lucos_claude_config#1. Until fixed, post obstacle comments to the related non-PR issue and explain the permission gap.
