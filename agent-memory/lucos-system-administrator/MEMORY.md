# lucos-system-administrator Memory

## Estate rollout repo discovery

Use GitHub API (Contents API or code search), NOT local `grep -rl` against `~/sandboxes/`. Local clones are stale and incomplete — 6 repos were missed in the #34 rollout this way. See `estate-rollout-discovery.md`.

## GitHub App commit attribution (avatar display)

For commits to show a GitHub App's custom avatar, the git committer email must use the **bot user ID**, not the App ID. These are different numbers. Using App ID gives a grey ghost avatar.

Format: `{bot_user_id}+{bot_name}@users.noreply.github.com`

**Canonical source of truth**: `~/sandboxes/lucos_agent/personas.json` — contains all per-persona identity data (`bot_user_id`, `bot_name`, `app_id`, `installation_id`, `pem_var`). Do not duplicate this data in memory files.

Note: the lucos-code-reviewer commit email uses the login `lucos-code-reviewer[bot]` (lowercase) even though the display name is `lucOS Code Reviewer[bot]` (mixed case).

Get user ID via: `curl -s 'https://api.github.com/users/lucos-agent%5Bbot%5D' | jq .id`

Use `~/sandboxes/lucos_agent/git-as-agent --app <persona-name>` for all commit-writing git operations — never `git config` which would affect all subsequent commits. The wrapper reads identity from `personas.json` and prepends the correct `-c` flags automatically.

**The wrapper must be used for EVERY commit-writing git operation**, including `--amend`. When amending, git preserves the original author but sets a new committer using the current identity — which without the wrapper falls back to the global config (`lucos-agent[bot]`). This produces a mismatched author/committer. Confirmed bug in commit `b207d1e` on `lucos_agent` (2026-03-02).

`git-as-agent` was created 2026-03-07 specifically to prevent this class of error.

## Claude Code permissions: correct settings.json format

The correct key for bypassing permission prompts is `permissions.defaultMode`, NOT the top-level `dangerouslySkipPermissions`. The latter is silently ignored.

Also requires `"teammateMode": "tmux"` — in-process teammates hardcode `permissionMode: "default"` and ignore `bypassPermissions`. Tmux teammates inherit the parent session's mode. Must be run inside a tmux session (`.bashrc` auto-attaches on login). See `bypass-permissions-tmux.md` for full details and troubleshooting.

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

Claude Code caches persona files (`~/.claude/agents/*.md`) at conversation start. Changes made mid-conversation are NOT picked up by new teammate agent invocations within the same conversation. A Claude restart is required for agents to receive updated persona files.

Confirmed 2026-03-06: restructured the SRE persona file mid-conversation but the SRE agent still received the old version in subsequent invocations within that same session.

## Persona ops-checks restructure (2026-03-06)

Extracted ops checks for SRE, sysadmin, and security into separate `*-ops-checks.md` files in `~/.claude/agents/`. Changes committed to `lucos_claude_config`. Requires a fresh Claude session to pick up persona file changes (see caching note above).

## lucos_arachne one-shot containers (confirmed 2026-03-06)

`lucos_arachne_ingestor`, `lucos_arachne_triplestore`, and `lucos_arachne_search` all have `restart: no` — they are intentional one-shot containers that run to completion and exit. They will always appear in `Exited` state between runs. Do NOT raise issues for these containers being stopped.

`lucos_arachne_web` and `lucos_arachne_explore` are the persistent services that should always be `Up`.

## lucos_docker_health: new service (2026-03-10)

A new service `lucas42/lucos_docker_health` was created to monitor Docker container healthchecks across all hosts. Design (from lucos#45): a Go binary runs periodically on each host, reads local Docker healthcheck states, and pushes results to `lucos_schedule_tracker`. Uses `system` value `lucos_docker_health_{hostname}` (e.g. `lucos_docker_health_avalon`). Status is `error` if any container is unhealthy (with message), `healthy` otherwise.

This means healthcheck monitoring will eventually be visible via `lucos_monitoring` (which polls schedule_tracker). When deployed, this will supersede the manual unhealthy-container check I do in ops checks. Implementation issues are tracked on `lucas42/lucos_docker_health`.

## Missing `restart: always` — silent failure pattern

Containers without `restart: always` will stay down after a host reboot or a `docker compose stop`. This looks like an unexplained outage but is just missing config. Confirmed by lucos_comhra#2 (closed superseded by #3). When investigating containers that stopped without an obvious crash, check for missing restart policy before raising an outage issue.

## Check for existing issues before raising new ones

Before filing a new issue for an ongoing condition (crash-loops, service down, etc.), search open issues in the same repo first. Duplicate issues create noise and wasted triage work. Examples:
- lucos_repos#38 was filed simultaneously with lucos_repos#39 by two different agents — issue-manager closed #38 as a duplicate.
- lucos_repos#53 (CodeQL required status check convention) was closed as duplicate of #52, which already tracked the same requirement. Always search lucos_repos open issues before raising new convention requests there.
- lucos_deploy_orb#39 (PORT validation) was a duplicate of #40 filed by another agent at almost the same time during incident follow-up (2026-03-19).

**During incident follow-ups, duplicate risk is highest** — multiple agents often respond simultaneously. Search is not sufficient if another agent filed seconds before you. When in doubt during active incidents, message teammates first to coordinate before filing.

## Docker healthcheck localhost→IPv6 false-negative pattern

Docker healthchecks using `wget http://localhost/_info` (or `curl http://localhost/_info`) can silently fail if nginx binds only to `0.0.0.0:80` (IPv4). Inside Alpine-based containers, `localhost` resolves to `::1` (IPv6) first. wget/curl then get "Connection refused" and report unhealthy, even though the service is externally functional.

Fix: use `http://127.0.0.1/_info` (explicit IPv4) in healthcheck probe commands rather than `http://localhost/_info`.

Alternatively: add `listen [::]:80;` to the nginx config to also bind IPv6. The explicit IP approach is simpler and doesn't require nginx config changes.

Found in `lucos_arachne_web` (2026-03-09) — 542 consecutive failures. Documented in lucos_arachne#87. Worth sweeping other containers that use `localhost` in their healthchecks.

## avalon memory pressure: lucos_photos_redis (confirmed 2026-03-08)

`lucos_photos_redis` was consuming **2.3GiB** with no `maxmemory` limit — the single largest memory consumer on avalon (30% of host RAM). Redis defaults to unbounded growth. lucos_photos#112 tracks adding `maxmemory` with `allkeys-lru` eviction.

Swap on avalon was increased from 512MB to 4.5GB by adding a `/swapfile` (4GB swapfile + original `/dev/sda3` partition). The `lucos-agent` SSH user lacks root/sudo on avalon, so this required a human to run the `dd`/`mkswap`/`swapon`/`fstab` commands.

## Nginx upstream DNS resolution pattern (lucos_arachne#60)

When nginx starts before upstream containers, it fails to resolve upstream hostnames at startup and crash-loops. Fix: use variable-based upstream hostnames in `proxy_pass` with `set $upstream_host "hostname";`. This defers DNS resolution to request time. Also requires `resolver 127.0.0.11 valid=30s;` (Docker's embedded DNS resolver). Apply to all upstream `location` blocks.

## npm global install: always use user-writable prefix

**Never install Claude Code (or any tool needing auto-update) as root via `npm install -g`.** Root-owned `/usr/lib/node_modules/` blocks auto-update (EACCES). Fix:

1. `mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global` — creates user-writable prefix (writes to `~/.npmrc`)
2. `npm install -g @anthropic-ai/claude-code` — installs to `~/.npm-global/lib/node_modules/`
3. Add `~/.npm-global/bin` to PATH in `~/.profile` (before Lima's `/usr/sbin:/sbin` addition so it takes precedence over `/usr/bin/claude`)

Applied to live VM (2026-03-11) and `lucos_agent_coding_sandbox/lima.yaml` (commit fb3e335). The lima.yaml provisioning now does this in `mode: user` instead of `mode: system`.

## Docker healthcheck tool availability: check final image stage

When adding healthchecks, verify the probe tool is installed in the **final** image stage (not just the build stage). See `healthcheck-notes.md` for details.

## Docker volume restore procedure (CRITICAL — avoids label loss)

**Never restore a volume using `docker run` + alpine tar directly into a new volume.** This creates the volume without Docker Compose labels, breaking lucos_backups tracking and blocking deploys.

**Correct procedure:**
1. Stop all containers using the volume
2. Tar the live data OUT first: `docker run --rm -v <vol>:/source:ro -v /tmp:/backup alpine tar czf /backup/<vol>.live.tar.gz -C /source .`
3. Remove stopped containers: `docker rm <container>`
4. Remove the old volume: `docker volume rm <vol>`
5. Create the new volume WITH labels: `docker volume create --label com.docker.compose.project=<project> --label com.docker.compose.version=2.27.1 --label com.docker.compose.volume=<shortname> <vol>`
6. Restore data into it: `docker run --rm -v <vol>:/volume -v /tmp:/backup:ro alpine sh -c 'cd /volume && tar xzf /backup/<vol>.live.tar.gz'`
7. Trigger a CircleCI redeploy (not `docker start`) to bring containers back up properly under compose

Labels required by lucos_backups: `com.docker.compose.project`, `com.docker.compose.version`, `com.docker.compose.volume`. Volumes without these labels crash lucos_backups tracking for the entire host. Confirmed incident: 2026-03-17 EXIF reprocess cascade.

