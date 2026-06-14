---
name: docker-dnat-docker-user-bypass
description: DOCKER-USER filters post-DNAT ports — containers with container port 80 on non-80 host ports bypass lucos_firewall's allow-list
metadata:
  type: project
---

## The bug

`lucos_firewall` generates DOCKER-USER rules using `--dport <declared_port>`. In the FORWARD chain, Docker's DNAT has **already** rewritten the destination port (it runs in nat PREROUTING, before FORWARD). So `--dport 80` matches any packet DNAT'd to container port 80 — regardless of the original host port.

Any container published as `host_port→80/tcp` where `host_port ≠ 80` bypasses DOCKER-USER's DROP because:
- DNAT rewrites: `dst=host:8033` → `192.168.208.7:80`
- DOCKER-USER checks: `--dport 80` → MATCH on the declared public port 80 rule

## Confirmed on avalon (2026-06-14)

9 services externally reachable without lucos_router auth:
- `lucos_arachne_web` (8033→80) — confirmed via curl
- `lucos_contacts_web` (8013→80)
- `lucos_eolas_web` (8032→80)
- `lucos_locations_otfrontend` (8028→80)
- `lucos_mail_docs` (8022→80)
- `lucos_media_metadata_manager` (8020→80)
- `lukeblaney_blog` (8037→80)
- `lukeblaney_co_uk` (8025→80)
- `semweb` (8029→80)

Note: services where host port = container port (e.g. `lucos_router` on 80→80) are unaffected.

## Fix applied — lucos_firewall#21 (merged 2026-06-14 22:44Z)

Changed `--dport` to `-m conntrack --ctorigdstport` in DOCKER-USER ACCEPT rules in both `generateIPv4Ruleset` and `generateIPv6Ruleset`. The `xt_conntrack` module is already in use in the same ruleset (`--ctstate ESTABLISHED,RELATED`), so `--ctorigdstport` was available without additional kernel modules.

INPUT rules (host-destined traffic, never DNAT'd) left unchanged — still use `--dport` correctly.

**Verified post-deploy (2026-06-14 ~23:00Z):** All 9 services confirmed BLOCKED — no HTTP response on external curl against host ports 8033, 8013, 8032, 8028, 8022, 8020, 8037, 8025, 8029. All three deploy jobs (avalon, xwing, salvare) succeeded; lucos_firewall container on avalon restarted at 22:48:47Z.

**Why:** Network address translation (NAT PREROUTING) runs at hook priority -100; filter FORWARD at 0. Post-DNAT state is what FORWARD sees. This is a fundamental netfilter ordering rule, not a Docker quirk.
