---
name: firewall-rollout
description: lucos_firewall ADR-0007 default-deny rollout — dry-run logs ruleset NOT packets, router 172.17.0.1 hairpin is the enforce single-point-of-failure
metadata:
  type: project
---

# lucos_firewall enforce rollout (lucos#182)

Status 2026-06-08: all 3 hosts (xwing, salvare, avalon) running `lucas42/lucos_firewall:1.0.6` in DRY_RUN, image includes #14 (28 `-i br+ -j RETURN` lines in dry-run log = #14 live). Rollout order xwing→salvare→avalon, flip is lucas42's call per host.

## CRITICAL: dry-run logs the RULESET, not would-deny packets
- DRY_RUN mode logs `[DRY-RUN] Would apply via iptables-restore: <full ruleset>`. There is **NO `-j LOG`/NFLOG target** anywhere — `INPUT DROP` policy and `-A DOCKER-USER -j DROP` are *silent*. So there is **no would-deny packet log to review**. Any pre-enforce review is static coverage-analysis (allow-list vs listening/published ports), not empirical traffic observation.

## The 172.17.0.1 hairpin = enforce single point of failure
- Nearly every web service is published `0.0.0.0:<high-port>` (8016/8017 on xwing; 8001-8038/3000-3002 on avalon) and is NOT in the configy allow-list.
- lucos_router reaches them via `proxy_pass http://172.17.0.1:<port>` (docker0 host-gateway hairpin), NOT a shared docker network (each service on its own `<svc>_default` bridge).
- Survival under enforce rests ENTIRELY on #14: router pkt ingresses on `br-<router>` (matches `br+`) → `-i br+ -j RETURN` → not dropped. Analysis says survives; NEVER tested against live traffic (#13/#14 worked examples were classic ICC + cross-bridge, not the host-gateway hairpin).
- Direct external→8016/8017 etc. WOULD be dropped on enforce = intended hardening, not a regression.

## Auto-rollback guardrail does NOT cover hairpin failure
- CONFIRM_TIMEOUT auto-rollback only re-checks configy reachability. configy is on avalon and stays reachable from xwing regardless. So a broken router hairpin on xwing would NOT self-revert — private.l42.eu/staticmedia.l42.eu would silently break until noticed. Need human watching + ready manual revert (firewall_enforce=false in configy) on each flip.

## Per-host (2026-06-08 assessment)
- **xwing**: allow-list {22,53,80,443}. Hairpin services lucos_private(8016)+lucos_static_media(8017). READY as canary — flipping it is the live empirical test of the hairpin that avalon depends on. Watch private/staticmedia immediately post-flip.
- **salvare**: trivially safe — no router, no published ports, SSH-only inbound. Minor: inbound mDNS 5353/udp dropped under enforce (harmless unless LAN discovery needs salvare to answer). DHCPv6(546) survives via conntrack ESTABLISHED.
- **avalon**: highest blast radius — ~35 hairpin services PLUS `bridge-nf-call-iptables=1` so same-bridge ICC (app→postgres) also traverses DOCKER-USER and rides on #14. Flip LAST, only after xwing proves hairpin under enforce.

## bridge-nf-call-iptables (#13 sysctl finding)
avalon=1 (same-bridge ICC hits iptables), xwing/salvare br_netfilter not loaded (same-bridge ICC bypasses iptables; cross-bridge still hits FORWARD).
