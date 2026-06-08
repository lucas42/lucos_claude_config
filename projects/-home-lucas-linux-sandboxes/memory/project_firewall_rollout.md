---
name: firewall-rollout-state
description: "lucos_firewall (ADR-0007) rollout state — xwing ENFORCED 2026-06-08; salvare + avalon still dry-run via configy"
metadata: 
  node_type: memory
  type: project
  originSessionId: f9e2917c-8177-41f8-a17d-a299feb63d76
---

ADR-0007 estate-wide default-deny firewall. Rollout tracked in `lucas42/lucos#182`.

**Enforce order: xwing → salvare → avalon** (avalon last — remote, no out-of-band console).

## Current state (2026-06-08)

- **xwing: ENFORCED** as of 10:45:46 UTC 2026-06-08. "Rules confirmed and active" — hairpin clean, no auto-revert, no manual revert needed. Canary passed.
- **salvare: dry-run via configy** (`firewall_enforce: false`, no public-facing services — base-only rules expected when enforced)
- **avalon: dry-run via configy** (`firewall_enforce: false`)

## Key operational notes learned this session

**DRY_RUN env var overrides configy unconditionally.** `DRY_RUN=true` was present in production lucos_firewall creds throughout the dry-run period. lucas42 removed it 2026-06-08 before the enforce flip. The documented "flip = set firewall_enforce in configy" mechanism only works once DRY_RUN is cleared from creds + container redeployed. Future host enforce flips now work via configy alone (no DRY_RUN in creds).

**Revert path for enforce failures** (hairpin/service breaks): `ssh <host> 'docker exec lucos_firewall /usr/sbin/iptables -D DOCKER-USER -j DROP && docker exec lucos_firewall /usr/sbin/ip6tables -D DOCKER-USER -j DROP'` — removes the terminal DROP, FORWARD policy ACCEPT means traffic falls through. The firewall's hash-dedup means it won't re-apply DROP on next poll (ruleset unchanged → skip). Also push a configy revert (`firewall_enforce: false`) as the secondary backstop (~10 min CI lag). The auto-rollback (30s configy reachability check) does NOT catch hairpin failures — only catches broken outbound from the host.

**Enforce flip sequence** (for salvare and avalon when ready):
1. `firewall_enforce: true` for the host in lucos_configy hosts.yaml → PR → merge → configy CI deploys on avalon (~5 min Rust build)
2. Within ≤60s the host's firewall polls, reads enforce=true, calls `applyWithRollback`
3. 30s confirm window → "Rules confirmed and active" or auto-reverts
4. SRE watches hairpin; sysadmin holds revert command ready

**lucos_firewall#15** (P3/hygiene): salvare generates "fallback mode — configy unreachable or no ports declared" comment even when configy is reachable + 0 ports — cosmetic, not blocking.

## Build history

- 2026-06-01: firewall shipped, all three hosts in DRY_RUN
- 2026-06-08: PR #14 merged (inter-container RETURN fix), DRY_RUN removed from creds, xwing enforced
- lucos_firewall#15 raised (salvare comment wording)
