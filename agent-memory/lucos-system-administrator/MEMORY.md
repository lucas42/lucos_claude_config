# lucos-system-administrator Memory

## GitHub App commit attribution (avatar display)

For commits to show a GitHub App's custom avatar, the git committer email must use the **bot user ID**, not the App ID. These are different numbers.

Format: `{USER_ID}+{app-name}[bot]@users.noreply.github.com`

| App | Bot name | Bot User ID | Correct commit email |
|---|---|---|---|
| lucos-agent | `lucos-agent[bot]` | 263775988 | `263775988+lucos-agent[bot]@users.noreply.github.com` |
| lucos-issue-manager | `lucos-issue-manager[bot]` | 264038870 | `264038870+lucos-issue-manager[bot]@users.noreply.github.com` |
| lucos-code-reviewer | `lucOS Code Reviewer[bot]` | 264151378 | `264151378+lucos-code-reviewer[bot]@users.noreply.github.com` |

Note: the lucos-code-reviewer commit email uses the login `lucos-code-reviewer[bot]` (lowercase) even though the display name is `lucOS Code Reviewer[bot]` (mixed case).

Get user ID via: `curl -s 'https://api.github.com/users/lucos-agent%5Bbot%5D' | jq .id`

The App ID is only used for JWT authentication (in `get-token`). Using App ID in the email gives a grey ghost avatar.

Always use `git -c user.name="..." -c user.email="..."` on the commit command itself — never `git config` which would affect all subsequent commits.

Current VM git config is correct (fixed 2026-02-27). `lima.yaml` in `lucos_agent_coding_sandbox` updated to match.

See: `/home/lucas.linux/sandboxes/lucos_agent/CLAUDE.md` for full app details.
