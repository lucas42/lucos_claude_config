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
