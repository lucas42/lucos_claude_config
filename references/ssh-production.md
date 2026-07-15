# SSH Access to Production Hosts

> **WARNING: These are PRODUCTION systems.** Treat every command with the same caution you would use when defusing something. Read-only operations are strongly preferred. Do not change anything unless you are certain it is necessary and safe — and always confirm with the user before making changes on production. Never restart services, delete files, or modify configuration without explicit instruction.

## Finding the list of hosts

The authoritative list of hosts is in `lucos_configy/config/hosts.yaml` (at `~/sandboxes/lucos_configy/config/hosts.yaml`).

## Host naming

Hosts have a short name (e.g. `avalon`) and a full domain (`avalon.s.l42.eu`). These are interchangeable — the user may use either form and they refer to the same host. The full domain always follows the pattern `<shortname>.s.l42.eu`.

## Checking whether a host is active

Before attempting to contact a host, check the `active` field in `hosts.yaml`:

- If `active: false` is set, the host is **offline** — do not attempt to SSH into it
- If the `active` field is absent, the host is **active** (active is the default)

## Connecting via SSH

SSH config is already set up in this environment. Simply use:

```bash
ssh <shortname>.s.l42.eu
```

No need to specify `-i` (the key is configured automatically) or `-l` (the user is configured automatically).

## Before making changes on production

Before executing any write operation on a production host, send a Loganne event to signal the activity. If the change involves multiple steps, one event covering the full action is sufficient — you do not need to send one per command.

```bash
~/sandboxes/lucos_agent/loganne-event plannedMaintenance "Brief description of what you are about to do"
```

This allows other agents (especially `lucos-site-reliability`) to distinguish intentional changes from unexpected incidents.

## Production host directory structure

There are **no persistent per-service directories** on production hosts. Docker Compose files are deployed transiently to `/home/circleci/project` during CI deploys and are **not present** after the deploy completes.

When working on production, always use `docker` commands with the container name directly — do not attempt to `cd` into a service directory:

```bash
# Correct — use container name directly
docker logs monitoring
docker stop time
docker exec -it lucos_arachne_web sh

# Wrong — these paths do not exist on production
cd /home/docker/lucos_time          # does not exist
cd /home/lucas/sites/lucos_time     # will not have docker-compose.yml after deploy
```

If you need the current docker-compose configuration for a running service, retrieve it from the GitHub repo, not from the production host filesystem.

## Sudo access is deliberately near-zero

The `lucos-agent` SSH account's sudo grant is near-zero, but **it is not identical across hosts — check per host, don't generalise from one to another:**

- **xwing, salvare**: `sudo -n -l` succeeds and shows exactly `(ALL) NOPASSWD: /usr/bin/apt list --upgradable` — nothing else.
- **avalon**: `lucos-agent` has **no sudo grant at all**. `sudo -n -l` and `sudo -n /usr/bin/apt list --upgradable` both return `sudo: a password is required` — even the apt-list-only entry the other two hosts have is absent. (Plain `apt list --upgradable`, run without `sudo`, works fine there — it's a read-only operation that never needed root, which is why this gap went unnoticed for a while.)

(Directly verified per-host via `sudo -n -l` — 2026-07-14, `lucos_agent_coding_sandbox#95`; avalon re-confirmed 2026-07-14 after an initial write of this note wrongly generalised xwing/salvare's grant to avalon without having actually captured avalon's `sudo -n -l` output.)

Either way, any `sudo` invocation beyond what's listed above — `apt upgrade`, a reboot, a root shell, anything — prompts for an interactive password no agent has. This is a deliberate least-privilege boundary, not a bug: don't try to work around it (no password prompting, no alternate escalation paths). Applying OS/package upgrades, rebooting a host, or any other root-level change is structurally a lucas42-only action; an agent's role is to investigate, document a runbook, and hand it to him — never to attempt the privileged command itself and hit the password prompt as a surprise mid-task.

## Claims about hosts: only claim what you actually probed

(This rule is general — it governs any multi-host claim, not just the sudo grants above.)

**When documenting a multi-host claim — a privilege grant, a config value, or the result of a survey/sweep — only write "verified on {hosts}" for hosts whose command output you actually captured in that session.** An observation (or its absence) on one host is not evidence for a sibling host, even when they're provisioned from the same playbook: write down what each host's probe actually returned, not what you'd expect it to return.

**Enumerate hosts from `lucos_configy/config/hosts.yaml` before claiming any total**, so a host cannot be silently omitted — and name each host you did *not* probe, with the reason (`active: false`, no Docker, no direct SSH), rather than letting it vanish into an "estate-wide" summary. A sweep run on one host is evidence for that host alone.

Both directions have bitten us:
- **Over-generalising from siblings** — 2026-07-14: the sudo note above was first written generalising xwing/salvare's grant to avalon without capturing avalon's own output (see the verification note in that section).
- **Reporting a single-host sweep as an estate conclusion** — 2026-07-15: an SRE survey for Python services ran on avalon alone and was reported as "the estate-wide problem doesn't exist". The follow-up xwing sweep then surfaced a container the avalon pass had missed entirely — the conclusion happened to survive, but the claim had outrun its evidence.

**Environmental facts are a separate class from command output, and plausibility is not a source.** Physical accessibility, hardware topology, hosting arrangement, who can reach what and how fast — none of this is probeable over SSH, so there is no "run the command and capture the output" fallback the way there is for a sudo grant. It's tempting to infer it anyway ("remote-only Pis obviously have no console") because the inference sounds reasonable — this happened on 2026-07-14 (`lucos_agent_coding_sandbox#95`'s runbook asserted the two Pi hosts had "no rollback console" and needed console access lined up before touching them; per lucas42 the opposite is true — xwing and salvare are physically accessible, avalon is not). A plausible-sounding environmental claim is not evidence. **Either it's sourced from lucas42 directly, or it's written down as explicitly unknown** ("physical accessibility of {host} is unconfirmed — ask lucas42") — never asserted from what seems likely given a host's role or remoteness.

## Safe read-only commands

When investigating production, prefer read-only commands such as:

```bash
docker ps                          # list running containers
docker logs <container_name>       # view container logs
docker compose ps                  # service status
df -h                              # disk usage
free -h                            # memory usage
uptime                             # load average
```
