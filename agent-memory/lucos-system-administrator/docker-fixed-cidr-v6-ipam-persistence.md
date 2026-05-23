---
name: docker-fixed-cidr-v6-ipam-persistence
description: docker daemon.json fixed-cidr-v6 only applies on bridge creation; existing IPAM state must be flushed to pick up changes
metadata:
  type: feedback
---

`fixed-cidr-v6` (and `fixed-cidr`) in `daemon.json` only apply when Docker **creates** the bridge network from scratch. If the bridge network already exists in Docker's persisted state, Docker uses the stored IPAM and ignores the daemon.json value — even after a full OS reboot.

**Why:** Observed during the salvare IPv6 incident (2026-05-23, lucos#179 follow-up). Daemon.json was changed to `fd42:dead:beef::/64` but docker0 kept `2a01:4b00:8598:5a00::/64`. Reboots did not help. The bridge "Created" timestamp updated but the IPAM came from persisted state.

**How to apply:** To change the bridge network's IPv6 CIDR:
1. `sudo systemctl stop docker`
2. `sudo rm -rf /var/lib/docker/network/files/`  (or at minimum `local-kv.db`)
3. `sudo systemctl start docker`

Docker will recreate all networks from scratch using the current daemon.json values. On Docker 29.x, state is in `/var/lib/docker/network/files/`. User-defined networks are lost and need to be recreated by running docker-compose up for each service. Built-in networks (bridge/host/none) are recreated automatically.

**What survives:** Containers with `live-restore: true` keep running. Host-network containers are unaffected. Bridge/custom-network containers lose their network until docker-compose up re-creates the network and reconnects them.

See also: [[docker-daemon-restart-risk]]
