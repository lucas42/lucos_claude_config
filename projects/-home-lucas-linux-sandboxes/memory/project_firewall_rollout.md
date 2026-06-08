---
name: firewall-rollout-state
description: "lucos_firewall (ADR-0007) rollout COMPLETE — all three hosts enforcing 2026-06-08; lucos#182 closed. Durable operational lessons retained."
metadata:
  node_type: memory
  type: project
  originSessionId: f9e2917c-8177-41f8-a17d-a299feb63d76
---

ADR-0007 estate-wide default-deny firewall. Rollout tracked in `lucas42/lucos#182` — **COMPLETE and closed 2026-06-08**.

## Final state (2026-06-08)

All three hosts enforcing (INPUT = DROP), each via a gated/watched canary; no firewall revert ever needed:
- **xwing** ENFORCED 10:45:46 UTC
- **salvare** ENFORCED 10:59:32 UTC (base-rules-only, no public ports)
- **avalon** ENFORCED 14:25:12 UTC (last; remote, highest blast-radius)

SRE confirmed estate stable 17:06 UTC, all firewall-related monitoring green. Sole outstanding estate red is `lucas42/lucos_backups#309` (create-backups timeouts) — pre-existing, unrelated to the firewall.

## Post-enforce regressions found + fixed (all closed)

1. **Inter-container DROP** — `lucos_firewall#13` → #14. DOCKER-USER terminal DROP also policed inter-container traffic. Fix: `-i br+/-i docker0 -j RETURN`. Cross-stack scope = **Option A** (firewall exempts ALL inter-container traffic; cross-stack isolation is app-auth's job, not the firewall). ADR reconciled in `lucos#232`.
2. **Docker FORWARD-chain wipe** — `lucos_firewall#19` → #20. `iptables-restore` without `--noflush` wiped Docker 29.x FORWARD jumps estate-wide, breaking new network creation. Fix: `--noflush` + idempotent `iptables -C FORWARD -j DOCKER-USER || -I FORWARD 1 -j DOCKER-USER`. v1.0.10. **One-time manual recovery of all 6 Docker 29.x chains on all three hosts** was needed (old code had already deleted them; `live-restore: true` means a daemon restart won't recreate them).
3. **mDNS `.local` severed** — `lucos_firewall#16` → #17 (ADR-0007 Amendment 3). Base-allow carve-out for link-local mDNS (`224.0.0.251`/`ff02::fb`). Durable fix = aurora onto router-served unicast DNS (`aurora.lan`), tracked in `lucos_backups#306` (4 PRs).
4. **backups host-net hairpin dropped** — `lucos_backups#307` → #310. Router hairpin to a `network_mode: host` container lands on INPUT (default DROP), not FORWARD, so the `br+` RETURN exemption doesn't apply. Fix: bridge backups onto an `enable_ipv6` ULA network (`fd00:3::/64`) so it rides FORWARD; IPv6→salvare preserved via NAT66 (no daemon change — Docker 29.3 enables ip6tables by default).

## Durable operational lessons (reusable beyond this rollout)

- **DRY_RUN env overrides configy unconditionally.** `DRY_RUN=true` in firewall creds beats configy `firewall_enforce`. The enforce flip = remove DRY_RUN from creds → redeploy → set `firewall_enforce: true` per-host in configy. (lucas42 removed DRY_RUN from prod creds 2026-06-08; future flips are configy-only.)
- **Revert hand** (hairpin/service break under enforce): `ssh <host> 'docker exec lucos_firewall /usr/sbin/iptables -D DOCKER-USER -j DROP && docker exec lucos_firewall /usr/sbin/ip6tables -D DOCKER-USER -j DROP'`. Hash-dedup means it won't re-apply. The 30s auto-rollback only checks configy reachability — it does NOT catch hairpin/inter-container breakage.
- **Compose foot-gun (SRE-flagged, worth remembering):** Docker Compose **silently reuses an existing network instead of recreating it when its config changes**. backups#310's `enable_ipv6: true`/`fd00:3::/64` never took effect because a stale Sept-2024 `lucos_backups_default` (IPv4-only) network was reused — `EnableIPv6=false` despite a correct compose. Fix: force-recreate (`docker network rm` + redeploy). This will bite ANY future host-net→bridge migration that adds IPv6. Candidate for the architect's `lucos#234` addendum.
- **Host-net + router-fronted pattern** (`lucos#234`, Ideation): host-networked containers fronted by lucos_router land in INPUT, not FORWARD — so the firewall drops their hairpin. Bridging is the fix.
