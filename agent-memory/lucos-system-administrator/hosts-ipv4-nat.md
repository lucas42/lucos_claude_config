---
name: hosts-ipv4-nat
description: hosts.yaml ipv4_nat field means shared NAT — not the host's own IP; only ipv4 is a direct address
metadata:
  type: feedback
---

`ipv4_nat` in `lucos_configy/config/hosts.yaml` is a **shared NAT address** — multiple hosts can share the same value. It is NOT the host's own IP.

- `ipv4` (no suffix): the host's own public IPv4. SSH to this goes to that specific host.
- `ipv4_nat`: the NAT gateway's public IP. SSH to this goes to the NAT gateway (e.g. xwing), not the named host.

**Example:** salvare has `ipv4_nat: 152.37.104.10`. xwing has `ipv4: 152.37.104.10`. SSH to `152.37.104.10` reaches xwing, not salvare.

**Why:** Salvare and virgon-express sit behind xwing's NAT. They only have IPv6 addresses for direct external access. If their IPv6 is down, there is no SSH path from the agent VM — only from the local LAN via `salvare.local`.

**How to apply:** Before using `ipv4_nat` to SSH into a host, check if `ipv4` is set. If only `ipv4_nat` is present (or if `ipv4_nat == some other host's ipv4`), that IP does NOT reach this host directly. Use the hostname (`salvare.s.l42.eu`) which resolves to the AAAA record, or access via the LAN.
