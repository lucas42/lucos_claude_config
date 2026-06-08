---
name: firewall-rollout
description: lucos_firewall ADR-0007 default-deny rollout — dry-run logs ruleset NOT packets, router 172.17.0.1 hairpin is the enforce single-point-of-failure
metadata:
  type: project
---

# lucos_firewall enforce rollout (lucos#182)

Status 2026-06-08: all 3 hosts running `lucos_firewall` with #14 (28 `-i br+ -j RETURN` lines = #14 live). Rollout order xwing→salvare→avalon, flip is lucas42's call per host.

**salvare FLIPPED TO ENFORCE 2026-06-08 10:59 — CLEAN.** `10:59:02 effective: enforce` → `10:59:32 Rules confirmed and active` (no auto-revert). SSH/22 up every 8s poll across the window; real SSH login verified under enforce (`SSH_LOGIN_OK`); ICMP up. mDNS dropped, zero impact (harmless case confirmed). Containers (linuxplayer, docker_health, backups) all outbound-only, unaffected. salvare signal = SSH reachability + host up + firewall confirm (no hairpin to watch). 2 of 3 hosts now enforced; avalon remaining.

**xwing FLIPPED TO ENFORCE 2026-06-08 10:45 — CLEAN, hairpin HELD (empirical proof).** Sequence: `10:45:16 effective: enforce` → IPv4+IPv6 applied → 30s confirm → `10:45:46 Rules confirmed and active` (no auto-revert). private.l42.eu + staticmedia.l42.eu stayed 302 on every 8s fresh-connection poll right across the flip → **#14 br+/docker0 RETURN successfully exempts the live 172.17.0.1 router hairpin under enforce.** This is the proof the whole estate (esp. avalon's ~35 hairpin svcs) was riding on. xwing:80→301, 443→400 (allow-listed, reachable); 8016/8017→000 (blocked, but already were pre-flip). Enforce mechanism: DRY_RUN **env override** beats configy unconditionally — real flip = lucas42 redeploys clean (no DRY_RUN, image 1.0.7) THEN configy `firewall_enforce=true` PR merges → ~configy-CI + next 60s poll + 30s confirm before enforce applies (NOT instant on merge). Revert hand: `docker exec lucos_firewall iptables -D DOCKER-USER -j DROP` (seconds).

## ENFORCE SIDE EFFECT: xwing mDNS drop broke backups→aurora (2026-06-08 ~11:07)
- `lucos_backups/host-tracking-failures` went red post-flip. Root cause: aurora is a storage-only NAS, **no public IP, no real DNS — addressed ONLY by mDNS `aurora.local`**, and `ssh_gateway: xwing`. Backups (on avalon) SSH-proxies through xwing to aurora. xwing's enforce dropped inbound mDNS (UDP 5353) → xwing can no longer RESOLVE aurora.local (verified: `getent hosts aurora.local`=NOT RESOLVED under enforce, but by-IP 192.168.8.143:22=OK). paramiko error `Secsh channel open FAILED: Name or service not known` = jumphost xwing failing to resolve target.
- **mDNS is NOT harmless when an enforced host is an ssh_gateway for a .local-only host.** My pre-flip review called salvare mDNS harmless but missed xwing→aurora. Lesson: for each enforced host, check if it's an `ssh_gateway` for any host addressed by `.local` (configy `domain` ending .local + `ssh_gateway: <thishost>`).
- Fix: NOT a revert, NOT public_ports (5353 must not be public — reflection risk; and backups port is SSH/22 already allowed). Fix-forward = address aurora by static LAN IP 192.168.8.143 (configy `aurora.domain`) or give aurora real DNS. Proper firewall fix (follow-up): treat mDNS 5353 as link-local infra base-allow like NDP/ICMP, not a public port.
- **WRITE PATH ALSO AFFECTED, deadline 15:25 UTC.** create-backups (`backups.cron`: `25 3,15 * * *` = 03:25 & 15:25 UTC twice daily) WRITES volume archives to aurora's /share/backups via the same aurora.local-through-xwing gateway (`host.py` runOnRemote/copyFileTo → `ssh -o ProxyJump=xwing aurora.local`). 10:45 flip fell between runs → no run since enforce → check still green (20h freshness). Next run 15:25 UTC WILL fail aurora writes unless aurora.domain fixed first. Land the configy fix before 15:25 = both tracking+writes recover, enforce stays on, zero gap. Backups verified by reading actual 03:25 run log (`Copying ... to /share/backups/host/avalon/volume/ on aurora`).
- Home LAN = 192.168.8.0/24: salvare=.134, xwing=.234, aurora=.143. avalon NOT on home LAN (its 192.168.N.1 = docker bridge gateways). Before avalon flips: check nothing resolves a .local name via avalon.
- **xwing.local/salvare.local resolution from OTHER LAN hosts is ALSO broken under enforce** (tested: salvare can't getent xwing.local & vice-versa; self-resolve via 127.0.0.1 survives). But COSMETIC — nothing in the estate references them (all use *.s.l42.eu); only ad-hoc laptop/.local access affected.

## aurora .local landmine is BROADER than backups — 4 wiring points, configy fix covers only 1
- aurora is the ONLY .local-addressed host, wired in 4 places: (1) configy `aurora.domain` → backups tracking+writes [configy IP/DNS fix covers this]; (2-4) **NFS mounts hardcoding `addr=aurora.local` in 3 compose files, all on xwing**: lucos_private (rw /medlib), lucos_static_media (rw /medlib/public), lucos_media_import (ro /medlib/ceol srl).
- NFS mounts CURRENTLY HEALTHY (latent): `/proc/mounts` shows they resolved aurora.local→192.168.8.143 at mount time (pre-enforce) and hold the IP; data path xwing→.143:2049 outbound, unaffected. **Break on next restart/redeploy** of those 3 on xwing (re-resolve aurora.local fails). Operational guard: DON'T redeploy private/static_media/media_import on xwing until aurora addressing fixed in their compose.
- **configy aurora.domain fix does NOT cover the NFS mounts** (addr hardcoded in compose, not from configy). Strengthens the case for giving aurora a REAL DNS name (aurora.s.l42.eu→192.168.8.143) used everywhere, over sprinkling the IP in 4 spots.
- Transient SSH `kex_exchange_identification: Connection reset` to xwing during heavy polling = likely sshd MaxStartups throttling from my own check volume, NOT firewall (SSH/22 allow-listed; enforce would timeout not reset). Recovers on retry.

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
