# lucos-system-administrator Memory

## GitHub App commit attribution (avatar display)

For commits to show a GitHub App's custom avatar, the git committer email must use the **bot user ID**, not the App ID. These are different numbers. Using App ID gives a grey ghost avatar.

Format: `{bot_user_id}+{bot_name}@users.noreply.github.com`

**Canonical source of truth**: `~/sandboxes/lucos_agent/personas.json` — contains all per-persona identity data (`bot_user_id`, `bot_name`, `app_id`, `installation_id`, `pem_var`). Do not duplicate this data in memory files.

Note: the lucos-code-reviewer commit email uses the login `lucos-code-reviewer[bot]` (lowercase) even though the display name is `lucOS Code Reviewer[bot]` (mixed case).

Get user ID via: `curl -s 'https://api.github.com/users/lucos-agent%5Bbot%5D' | jq .id`

Always use `git -c user.name="..." -c user.email="..."` on the commit command itself — never `git config` which would affect all subsequent commits.

**The `-c` flags must appear on EVERY commit-writing git operation**, including `--amend`. When amending, git preserves the original author but sets a new committer using the current identity — which without `-c` flags falls back to the global config (`lucos-agent[bot]`). This produces a mismatched author/committer. Confirmed bug in commit `b207d1e` on `lucos_agent` (2026-03-02).

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

## lucos_media_weightings: known technical debt

`lucos_media_weightings` uses Python's built-in `BaseHTTPRequestHandler` — single-threaded, no connection timeouts. Two open issues split from #38 (2026-03-03):

- **#58**: Add `timeout=30` to `requests.get()`/`requests.put()` calls in `media_api.py` — small change, `agent-approved`
- **#59**: Replace `BaseHTTPRequestHandler` with Waitress (WSGI, handles connection lifecycle properly) — `agent-approved`

Decision made: use Waitress (not FastAPI) — simpler migration for a two-endpoint service.

## Design pattern: splitting broad issues

When assigned a `status:needs-design` issue that conflates multiple problems, the right approach is:
1. Post a design proposal comment identifying the distinct concerns
2. Leave a summary comment noting what needs a decision vs what is ready to implement
3. Let lucos-issue-manager handle the actual split — it will create child issues and close the parent

Don't try to split issues yourself (we don't have `issues: write` on new issue creation in all repos? — actually we do, but issue splitting is the issue manager's job per the label workflow).

## lucos_backups architecture

See `lucos_backups.md` for full details. Key points to avoid repeating past mistakes:

- **Single container on avalon** handles ALL hosts. Do NOT raise issues about xwing/salvare lacking lucos_backups.
- Prune script SSHes into all hosts (avalon, salvare, xwing) — it IS pruning salvare's backup files.
- `lucos_backups` has NO persistent volumes of its own (config cached in container filesystem).
- The `volume-config` health check fails if any Docker volume exists on a host but isn't registered in `lucos_configy/config/volumes.yaml`.

## Script repo structure (confirmed 2026-03-05)

The split between repos is intentional and confirmed by lucos-architect review (lucos_agent#11):

- **lucos_agent** (`~/sandboxes/lucos_agent/`) — GitHub API auth tooling: `get-token`, `gh-as-agent`, `get-issues-for-persona`, etc. All scripts authenticate via GitHub App. This is the canonical home for agent persona scripts that interact with GitHub.
- **lucos_claude_config** (`~/.claude/scripts/`) — cron maintenance of the Claude config repo itself (`commit-agent-memory.sh`). Self-referential by design — do NOT move this to `lucos_agent`.
- **lucos_agent_coding_sandbox** — VM provisioning only (`setup-repos.sh`, `lima.yaml`).

Do not raise issues about consolidating these repos.

## xwing TLS certificate renewal

Certificates on xwing are managed by certbot inside the `router` container (not `lucos_router_nginx` — xwing's router container is named `router`). Auto-renewal is via a daily cron at 22:16 running `/usr/bin/update-domains.sh`. Let's Encrypt typically renews at 30 days out. Certificates as of 2026-03-05 expire 2026-04-06 — expected to auto-renew.

**Do NOT raise issues for certificates that have auto-renewal configured.** lucos_agent_coding_sandbox#18 (raised 2026-03-05, closed `not_planned`) confirmed this: the team does not want warning issues when auto-renewal is in place. Only raise an issue if a certificate actually fails to renew past the 30-day mark.

## code-reviewer-auto-merge: PEM key formatting gotcha

When setting `CODE_REVIEWER_PRIVATE_KEY` as a GitHub Actions secret, the key from `~/sandboxes/lucos_agent/.env` is in lucos_creds space-flattened format (newlines replaced with spaces, wrapped in double quotes). The `actions/create-github-app-token@v2` action calls `atob()` which requires valid PEM with actual newlines — spaces cause `DOMException [InvalidCharacterError]: Invalid character`.

**Always convert before setting the secret.** Python conversion pattern:
```python
val = val.replace('-----BEGIN RSA PRIVATE KEY----- ', '-----BEGIN RSA PRIVATE KEY-----\n')
val = val.replace(' -----END RSA PRIVATE KEY-----', '\n-----END RSA PRIVATE KEY-----')
parts = val.split('\n')
body = parts[1].replace(' ', '\n')
pem = parts[0] + '\n' + body + '\n' + parts[2]
```

Then encrypt with PyNaCl using the repo's public key (`repos/{owner}/{repo}/actions/secrets/public-key`) and PUT to `repos/{owner}/{repo}/actions/secrets/CODE_REVIEWER_PRIVATE_KEY`.

This has caught out lucos_photos and lucos_repos (2026-03-04 and 2026-03-05).

## Planned maintenance notifications

When a planned reboot or maintenance window causes service disruption on avalon, notify via two channels:

1. **GitHub comment** on the most relevant open issue (e.g. the issue that motivated the maintenance): post immediately, while GitHub is still reachable. Include: what triggered the reboot, approximate time, and a clear "this is planned, not an incident" statement.
2. **Loganne event** (`POST https://loganne.l42.eu/events`, no auth required): post as soon as Loganne comes back up. Required fields: `source` (e.g. `lucos_agent`), `type` (e.g. `hostRebooted`), `humanReadable` (plain English description). Optional: `url` for a related issue or PR.

Loganne POST format:
```json
{ "source": "lucos_agent", "type": "plannedMaintenance", "humanReadable": "avalon rebooted to clear swap after Fuseki memory limit fix deployed", "url": "https://github.com/lucas42/lucos_agent_coding_sandbox/issues/16" }
```

Loganne will be unreachable during the reboot window (avalon hosts it). Post the GitHub comment first, then Loganne when it recovers.

## VM SSH key for git operations

SSH key for GitHub is at `~/.ssh/id_ed25519_lucos_agent` (no passphrase). Explicitly configured in `~/.ssh/config` for `github.com` with `IdentitiesOnly yes`. Works in cron's minimal environment — no SSH agent needed.

The auto-commit cron script at `~/.claude/scripts/commit-agent-memory.sh` also sets `GIT_SSH_COMMAND` explicitly to guarantee the correct key is used regardless of environment.

## Claude Code persona file caching

Claude Code caches persona files (`~/.claude/agents/*.md`) at conversation start. Changes made mid-conversation are NOT picked up by new Task tool invocations within the same conversation. A Claude restart is required for agents to receive updated persona files.

Confirmed 2026-03-06: restructured the SRE persona file mid-conversation but the SRE agent still received the old version in subsequent Task invocations.

## Persona ops-checks restructure (2026-03-06)

Extracted ops checks for SRE, sysadmin, and security into separate `*-ops-checks.md` files in `~/.claude/agents/`. Changes committed to `lucos_claude_config`. Requires a fresh Claude session to pick up persona file changes (see caching note above).

## lucos-architect MEMORY.md length issue

As of 2026-03-06, lucos-architect's MEMORY.md is 203 lines — 3 over the 200-line truncation limit — causing the User-Agent ADR convention entry to be lost. This still needs fixing: move older notes to a topic file to bring the main file under 200 lines.

## lucos_arachne one-shot containers (confirmed 2026-03-06)

`lucos_arachne_ingestor`, `lucos_arachne_triplestore`, and `lucos_arachne_search` all have `restart: no` — they are intentional one-shot containers that run to completion and exit. They will always appear in `Exited` state between runs. Do NOT raise issues for these containers being stopped.

`lucos_arachne_web` and `lucos_arachne_explore` are the persistent services that should always be `Up`.

## Missing `restart: always` — silent failure pattern

Containers without `restart: always` will stay down after a host reboot or a `docker compose stop`. This looks like an unexplained outage but is just missing config. Confirmed by lucos_comhra#2 (closed superseded by #3). When investigating containers that stopped without an obvious crash, check for missing restart policy before raising an outage issue.

## Check for existing issues before raising new ones

Before filing a new issue for an ongoing condition (crash-loops, service down, etc.), search open issues in the same repo first. Duplicate issues create noise and wasted triage work. Example: lucos_repos#38 was filed simultaneously with lucos_repos#39 by two different agents — issue-manager closed #38 as a duplicate.
