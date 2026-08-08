---
name: network-recreation-rollback-278
description: Live scratch note — rollback config recorded before each lucos#278 network recreation (xwing dns_secondary, avalon monitoring). Delete once both recreations confirmed successful.
metadata:
  type: project
---

# lucos#278 remaining network recreations — rollback values

Recorded per lucos-site-reliability's addition to the agreed plan (2026-08-09): capture
live config before deleting each network, so a failed recreate can be rolled back to the
old (IPv6-less but working) state instead of sitting in an unbounded outage like `lucos_time`.

## xwing — lucos_dns_secondary_default

Recorded 2026-08-09 immediately before action:
```
Subnet: 172.28.0.0/16
Gateway: 172.28.0.1
EnableIPv6: false
Driver: bridge
```
Rollback if redeploy fails after delete: `docker network create --subnet 172.28.0.0/16 --gateway 172.28.0.1 lucos_dns_secondary_default` then `docker compose up -d` (or trigger redeploy) to restore containers.

Declared target config (docker-compose.yml, origin/main): `enable_ipv6: true`, `subnet: fd00:3::/64`.

Status: PENDING

## avalon — lucos_monitoring_default

Recorded: (not yet — capture immediately before action, same pattern as above)
```
Subnet: 172.22.0.0/16
Gateway: (capture at time of action)
EnableIPv6: false
Driver: bridge
```
Declared target config: `enable_ipv6: true`, `subnet: fd00:1::/64`.

Status: NOT STARTED — do second, after xwing confirmed healthy. Do not schedule any other
avalon deploy during this window (monitoring's suppress-PUT `|| true` means other deploys
silently lose alert suppression while monitoring is down). Confirm recovery via
`curl https://monitoring.l42.eu/_info` from off-avalon, not via the dashboard.

## Delete this file once both recreations are confirmed successful and no longer need a rollback path.
