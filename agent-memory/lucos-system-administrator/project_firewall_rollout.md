---
name: firewall-rollout-state
description: "lucos_firewall (ADR-0007) rollout state — xwing + salvare ENFORCED; avalon draft PR #217 staged, awaiting GO"
metadata:
  type: project
---

ADR-0007 estate-wide default-deny firewall. Rollout tracked in `lucas42/lucos#182`.

**Enforce order: xwing → salvare → avalon** (avalon last — remote, no out-of-band console).

## Current state (2026-06-08)

- **xwing: ENFORCED** as of 10:45:46 UTC 2026-06-08. "Rules confirmed and active" — hairpin clean, no auto-revert.
- **salvare: ENFORCED** as of 10:59:32 UTC 2026-06-08. "Rules confirmed and active" — 0 public ports (no serves_http), base rules only. configy PR lucas42/lucos_configy#215.
- **avalon: DRY-RUN via configy** — lucos_firewall v1.0.9 deployed 14:16:50 UTC. Draft enforce PR: lucas42/lucos_configy#217. **Awaiting GO from team-lead before merge.**

## Avalon pre-merge verification (completed 2026-06-08 ~14:17 UTC)

1. ✅ Image: `lucas42/lucos_firewall:1.0.9` — Up, healthy
2. ✅ No `DRY_RUN` env var in container
3. ✅ Startup log: "Enforce mode will be read per-poll from configy" (not DRY_RUN override path)
4. ✅ configy reporting `firewall_enforce=false` (effective: dry-run) — correct pre-merge state
5. ✅ Fetched 7 public ports from configy for avalon (80, 443, 2202, 25, 53, 8883 etc.)
6. ✅ `docker exec lucos_firewall /usr/sbin/iptables -L DOCKER-USER -n` runs clean — revert hand proven

## Key operational notes learned this session

**DRY_RUN env var overrides configy unconditionally.** `DRY_RUN=true` was present in production lucos_firewall creds throughout the dry-run period. lucas42 removed it 2026-06-08 before the enforce flip. The documented "flip = set firewall_enforce in configy" mechanism only works once DRY_RUN is cleared from creds + container redeployed. Future host enforce flips now work via configy alone.

**Revert path for enforce failures** (hairpin/service breaks):
```bash
ssh <host>.s.l42.eu 'docker exec lucos_firewall /usr/sbin/iptables -D DOCKER-USER -j DROP && docker exec lucos_firewall /usr/sbin/ip6tables -D DOCKER-USER -j DROP'
```
Removes the terminal DROP. Hash-dedup means firewall won't re-apply DROP on next poll. Also push configy revert (`firewall_enforce: false`) as secondary backstop (~10 min CI lag). The auto-rollback (30s configy reachability check) does NOT catch hairpin failures.

**Enforce flip sequence:**
1. `firewall_enforce: true` for the host in lucos_configy hosts.yaml → PR → merge → configy CI deploys on avalon (~5 min Rust build)
2. Within ≤60s the host's firewall polls, reads enforce=true, calls `applyWithRollback`
3. 30s confirm window → "Rules confirmed and active" or auto-reverts

**mDNS fix (Amendment 3, v1.0.8):** xwing enforce blocked mDNS (UDP 5353) for `aurora.local` ProxyJump resolution in lucos_backups. Fix: (1) aurora domain changed to `aurora.lan` (PR lucas42/lucos_configy#216, awaiting lucas42 review); (2) mDNS base-allow rules added to firewall generators (PR lucas42/lucos_firewall#17, merged).

**NFS aurora.local → aurora.lan:** 3 repos have `addr=aurora.local` hardcoded in NFS compose opts. PRs open, do NOT redeploy until merged:
- lucas42/lucos_private#54
- lucas42/lucos_static_media#49
- lucas42/lucos_media_import#166

## Build history

- 2026-06-01: firewall shipped, all three hosts in DRY_RUN
- 2026-06-08: PR #14 merged (DOCKER-USER inter-container RETURN fix), DRY_RUN removed from creds
- 2026-06-08 10:45:46 UTC: xwing enforced
- 2026-06-08 10:59:32 UTC: salvare enforced via lucas42/lucos_configy#215
- 2026-06-08: lucos_firewall v1.0.8 — mDNS base-allow rules (PR #17)
- 2026-06-08: lucos_firewall v1.0.9 — nil vs empty ports comment fix (PR #18)
- 2026-06-08 14:16:50 UTC: v1.0.9 deployed to avalon. Draft enforce PR lucas42/lucos_configy#217 staged.
