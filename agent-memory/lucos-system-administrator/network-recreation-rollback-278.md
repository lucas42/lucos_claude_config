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

Status: **DONE 2026-08-09.** CI build+deploy succeeded (`lucos/deploy-xwing: success`).
`lucos_dns_secondary_bind`/`_check` both `Up ... (healthy)`. Network recreated with
`EnableIPv6=true`, `fd00:3::/64` + `172.28.0.0/16`. Dual-stack egress probe from a throwaway
container on the network confirmed both families work (IPv6 http=200 316ms, IPv4 control
http=200 260ms, cloudflare.com/cdn-cgi/trace). No rollback needed — safe to discard the
recorded 172.28.0.0/16 rollback value above.

## avalon — lucos_monitoring_default

Recorded 2026-08-09 immediately before action. Fresh drift check confirmed fd00:1::/64 still
unclaimed on avalon (avalon fd00:* map: fd00:2 dns, fd00:3 backups, fd00:4 time-post-fix).
```
Subnet: 172.22.0.0/16
Gateway: 172.22.0.1
EnableIPv6: false
Driver: bridge
```
Rollback if redeploy fails after delete: `docker network create --subnet 172.22.0.0/16 --gateway 172.22.0.1 lucos_monitoring_default` then trigger redeploy to restore containers.
Declared target config: `enable_ipv6: true`, `subnet: fd00:1::/64`.

Status: NOT STARTED — do second, after xwing confirmed healthy. Do not schedule any other
avalon deploy during this window (monitoring's suppress-PUT `|| true` means other deploys
silently lose alert suppression while monitoring is down). Confirm recovery via
`curl https://monitoring.l42.eu/_info` from off-avalon, not via the dashboard.

## Delete this file once both recreations are confirmed successful and no longer need a rollback path.
