---
name: firewall-rollout
description: lucos_firewall ADR-0007 default-deny rollout — dry-run logs ruleset NOT packets, router 172.17.0.1 hairpin is the enforce single-point-of-failure
metadata:
  type: project
---

# lucos_firewall enforce rollout (lucos#182)

Status 2026-06-08: all 3 hosts running `lucos_firewall` with #14 (28 `-i br+ -j RETURN` lines = #14 live). Rollout order xwing→salvare→avalon, flip is lucas42's call per host.

**xwing FLIPPED TO ENFORCE 2026-06-08 10:45 — CLEAN, hairpin HELD (empirical proof).** Sequence: `10:45:16 effective: enforce` → IPv4+IPv6 applied → 30s confirm → `10:45:46 Rules confirmed and active` (no auto-revert). private.l42.eu + staticmedia.l42.eu stayed 302 on every 8s fresh-connection poll right across the flip → **#14 br+/docker0 RETURN successfully exempts the live 172.17.0.1 router hairpin under enforce.** This is the proof the whole estate (esp. avalon's ~35 hairpin svcs) was riding on. xwing:80→301, 443→400 (allow-listed, reachable); 8016/8017→000 (blocked, but already were pre-flip). Enforce mechanism: DRY_RUN **env override** beats configy unconditionally — real flip = lucas42 redeploys clean (no DRY_RUN, image 1.0.7) THEN configy `firewall_enforce=true` PR merges → ~configy-CI + next 60s poll + 30s confirm before enforce applies (NOT instant on merge). Revert hand: `docker exec lucos_firewall iptables -D DOCKER-USER -j DROP` (seconds).

## Monitoring gotcha (my own tooling, bit me twice this session)
- Canary script alerting on `*502*|*503*|*000*` against the WHOLE curl output string false-matches the `time_total` digits (`0.033503s` contains "503"). Alert on the **http_code field only**.
- Detector greping `docker logs --since Nm` for state markers re-matches STALE pre-flip lines (`effective: dry-run` from before the flip is still in a 3m window). For post-flip failure detection, trigger ONLY on unambiguous failure markers (`Auto-reverting`/`Confirmation failed`), not on `effective: dry-run`, and use a tight `--since 90s`.

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
