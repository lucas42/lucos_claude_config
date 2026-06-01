# lucos-system-administrator Memory

## Docker live-restore skips ALL network init (incl. built-ins) when containers running
`docker restart` will never recreate bridge/host/none while containers are up. Stop all containers first. See `docker-live-restore-network-init-skip.md`.

## configy null serialisation — use `get(key) or default`, not `get(key, default)`
configy returns explicit `null` for absent fields — `dict.get(key, default)` passes `None` through. See `configy-null-serialisation.md`.

## aurora NAS — QNAP busybox host, storage-only
See `aurora-host.md`.

## Verify timeline before stating root cause
See `feedback_verify_timeline_before_stating.md`.

## Verify the premise of a dispatch before shipping a fix
False triggering events can make valid fixes ship for wrong reasons. See `feedback_verify_dispatch_premise.md`.

## Estate-wide incident investigation: always sweep ALL repos
Use `users/lucas42/repos?per_page=100`. A partial sweep missed 3 repos in the 2026-04-21 empty-secrets batch.

## GitHub API timestamps are UTC; VM is BST (UTC+1)
See `timezone-github-api.md`.

## xwing/salvare: accept_ra=2 applied (2026-04-20)
Docker forwarding=1 silently disables RA. Fix applied + persisted. See `xwing-ipv6-accept-ra.md`.

## Docker memswap_limit default
Unset = **2× mem_limit**. Set explicitly when intent is to prevent swap. See `docker-memswap-default.md`.

## Estate rollout merge pacing
No staggering needed — serial groups + calc-version rewrite resolved the 2026-04-16 rate-limit incident. See `estate-rollout-rate-limiting.md`.

## Estate rollout repo discovery
Use GitHub API, NOT local `grep -rl ~/sandboxes/`. See `estate-rollout-discovery.md`.

## GitHub App commit attribution (avatar display)
Email: `{bot_user_id}+{bot_name}@users.noreply.github.com`. Use `git-as-agent` for ALL commit-writing ops (including `--amend`) — never `git config`. Canonical source: `~/sandboxes/lucos_agent/personas.json`.

## Claude Code permissions: correct settings.json format
Key is `permissions.defaultMode` + `"teammateMode": "tmux"`. See `bypass-permissions-tmux.md`.

## GitHub App permissions: lucos-system-administrator
`pull_requests: write` (upgraded 2026-03-01). Can post PR thread comments, reviews, and issue comments.

## lucos_media_weightings: known technical debt
#58 (timeout) and #59 (Waitress) are `agent-approved`. Use Waitress, not FastAPI.

## Design pattern: splitting broad issues
Post design proposal → let lucos-issue-manager handle the split. Don't split issues yourself.

## lucos_backups architecture
Single container on avalon handles ALL hosts. See `lucos_backups.md`.

## Script repo structure (confirmed 2026-03-05)
`lucos_agent` = GitHub API tooling; `~/.claude/scripts/` = self-referential cron; `lucos_agent_coding_sandbox` = VM provisioning. Do not consolidate.

## xwing TLS certificate renewal
certbot auto-renews at 30 days. **Do NOT raise issues** for certs expiring >30 days. Only raise if cert fails to renew past the 30-day mark.

## code-reviewer-auto-merge: PEM key formatting gotcha
PEM keys from lucos_creds are space-flattened — convert before setting as GitHub Actions secrets. See `pem-key-formatting.md`.

## Planned maintenance notifications
Two channels: (1) GitHub comment pre-reboot; (2) Loganne `POST https://loganne.l42.eu/events` after recovery.

## VM SSH key for git operations
`~/.ssh/id_ed25519_lucos_agent` (no passphrase). commit-agent-memory.sh sets `GIT_SSH_COMMAND` explicitly for cron.

## Claude Code persona file caching
Persona files cached at conversation start. Mid-conversation changes need a fresh Claude session.

## lucos_arachne one-shot containers (confirmed 2026-03-06)
`lucos_arachne_ingestor`, `_triplestore`, `_search` have `restart: no` — always Exited between runs. Normal.

## lucos_arachne ingestor: startup auto-runs ingest.py (30s jitter)
Deploy itself is the verification trigger — no manual exec needed. Cron is once-daily `15 04 * * *`; startup run is the only timely post-deploy path. See `arachne-startup-autoingest.md`.

## lucos_arachne_triplestore memory limit (updated 2026-04-20)
2G mem / -Xmx1024m. TDB2 tombstones accumulate — compact with `POST http://localhost:3030/$/compact/ds`. See lucos_arachne#386.

## lucos_docker_health: new service (2026-03-10)
Go binary monitors Docker healthchecks per-host, pushes to lucos_schedule_tracker. Will supersede manual unhealthy-container check.

## Missing `restart: always` — silent failure pattern
Containers without `restart: always` stay down after reboot. Check policy before raising outage issue.

## Check for existing issues before raising new ones
Search open issues first — duplicate risk highest during active incidents. Also check recent 10 issues for different terminology.

## Docker healthcheck localhost→IPv6 false-negative pattern
`localhost` resolves to `::1` inside Alpine. Use `http://127.0.0.1/_info` in healthcheck probe. See lucos_arachne#87.

## avalon memory pressure history
Swap: 4.5GB total. Top consumer (2026-04-20): `lucos_photos_worker` at 1.4 GiB. `lucos_photos_redis` capped with `maxmemory` + `allkeys-lru`.

## Nginx upstream DNS resolution pattern
Variable-based upstream + `resolver 127.0.0.11 valid=30s;` defers DNS to request time. Prevents nginx crash-loop on start.

## npm global install: always use user-writable prefix
`npm config set prefix ~/.npm-global` → `npm install -g`. Add `~/.npm-global/bin` to PATH. Applied in lima.yaml (commit fb3e335).

## Docker healthcheck tool availability: check final image stage
Verify probe tool in **final** image stage, not just build stage. See `healthcheck-notes.md`.

## Docker volume restore procedure (CRITICAL — avoids label loss)
Never use bare `docker run` + alpine tar into new volume — loses compose labels, breaks lucos_backups. Use `docker volume create --label com.docker.compose.*` labels. Full 7-step procedure in MEMORY.md history (2026-03-17 incident).

## lucos_creds CircleCI env vars: manual rotation required
`KEY_LUCOS_MONITORING` and `LUCOS_DEPLOY_ENV_BASE64` are outside automatic rotation. 2026-05-09 incident: not updating LUCOS_DEPLOY_ENV_BASE64 caused reverted fix. See `lucos-creds-circleci-env-vars.md`.

## Docker daemon restarts: check live-restore first, prefer SIGHUP
`systemctl restart docker` without `live-restore` kills all containers. Use `systemctl reload docker` (SIGHUP) for hot-reloadable changes. See `docker-daemon-restart-risk.md`.

## GitHub Actions SHA pinning — always verify via API
Never write SHAs from memory. See `github-actions-sha-pinning.md`.

## Investigations: read source before theorising
See `feedback_read_before_theorising.md`.

## Triggering GitHub Actions workflow_dispatch directly
`gh-as-agent repos/lucas42/{repo}/actions/workflows/{id}/dispatches --method POST -f ref=main` — returns 204 on success.

## Volume removal pre-check: verify image content before removing masking volumes
See `volume-removal-image-verify.md`.

## `Load key … error in libcrypto` is a class; Docker Healthy ≠ end-to-end proof
CRLF/tilde/BOM all trigger libcrypto error. When fix survives live state but not redeploy, check for snapshot-based deploys (`grep DEPLOY_ENV_BASE64` in CI). `Healthy` status only proves the healthcheck.test — read it before citing as recovery proof. See `incident-2026-05-09-libcrypto.md`.

## Audit-finding issues: never auto-closed by the audit tool
Coordinator closes them once convention passes. See `feedback_audit_finding_no_autoclose.md`.

## Teammate quote verification rule (implemented lucos_claude_config#79)
Run `verify-teammate-quote --sender <name> --quote <text>` before quoting any teammate verbatim. See `feedback_verify_teammate_quotes.md`.

## Security tooling workflow changes: confirm lucos-security sign-off first
Before applying any workflow change that wires in a security tool config (CodeQL config-file, secret-scanning exclusions, etc.), check the developer consulted lucos-security. See `feedback_security_tooling_check.md`.

## hosts.yaml: ipv4_nat ≠ that host's IP
`ipv4_nat` is the shared NAT gateway address (e.g. xwing's IP). SSH to `ipv4_nat` reaches the NAT host, not the named host. Only `ipv4` (no suffix) is a direct address. Salvare and virgon-express have no direct IPv4 — only IPv6. See `hosts-ipv4-nat.md`.

## Production SSH: use `<host>.s.l42.eu`, never `<host>.l42.eu`, and let SSH config supply the user
`avalon.l42.eu` is NXDOMAIN. Correct form: `avalon.s.l42.eu`. SSH config sets `User lucos-agent` for `*.s.l42.eu` — never override with `lucas@`. SRE tripped on both mistakes (2026-05-30). See `ssh-hostname-convention.md`.

## Docker fixed-cidr-v6 IPAM persistence — flush network/files/ to pick up changes
`fixed-cidr-v6` in daemon.json only applies on bridge creation. Flush `/var/lib/docker/network/files/` + restart to change it. See `docker-fixed-cidr-v6-ipam-persistence.md`.

## Linux IPv6 route metric: linkdown at metric 256 beats UP at metric 600
Lower metric wins even if linkdown. docker0 with public /64 silently swallows all traffic. See `linux-ipv6-route-metric-linkdown.md`.

## DR assessment: bespoke corrections to external data are the irreplaceable part
"Source data still exists on NAS" doesn't mean the DB is reconstructable — check for bespoke fixes to bad source data and manual annotations built on top. See `feedback_dr_bespoke_correction_data.md`.
