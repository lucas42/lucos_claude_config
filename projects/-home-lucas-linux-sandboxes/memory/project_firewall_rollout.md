---
name: firewall-rollout-state
description: "lucos_firewall (ADR-0007) rollout state — dry-run live, enforce gated, 2026-06-08 review due"
metadata: 
  node_type: memory
  type: project
  originSessionId: f9e2917c-8177-41f8-a17d-a299feb63d76
---

ADR-0007 estate-wide default-deny firewall. As of 2026-06-01 the implementation is **shipped** (lucos_firewall#1 + FORWARD fix #6 merged; configy `public_ports` schema #189 + populated #190 merged; all repo conventions green). The firewall is **live in DRY_RUN on all three hosts since 2026-06-01 14:50 UTC**.

**Rollout tracked in `lucas42/lucos#182`.** Enforce order: **xwing → salvare → avalon** (avalon last — remote, no out-of-band console, so the timed auto-rollback is its sole safety net). Dry-run on all three in parallel; enforce each host only after its own clean dry-run review.

**ACTION DUE 2026-06-08** (≥7-day dry-run minimum): the local team (SRE + sysadmin — they have production SSH; a remote scheduled agent cannot read the hosts' `docker logs`, which is why this is session-triggered not a `/schedule` routine) reviews each host's dry-run "would-deny" set and reports readiness to begin enforcing xwing. On/after that date, dispatch the review. Reminder also posted as a comment on #182.

**BUILD COMPLETE as of 2026-06-01** — the per-host enforce-control mechanism is fully merged: `lucos_configy#203` (per-host `firewall_enforce` field + `/hosts/{host}` endpoint, PR #204) and `lucos_firewall#9` (firewall reads enforce-mode from configy per poll, PR #10 — incl. a fix for a silent enforce-skip bug where dry-run hash updates blocked the dry-run→enforce transition). ADR-0007 amendment (lucos PR #210) merged, design of record. `DRY_RUN` from creds can't differ per host — **flipping a host to enforce = setting `firewall_enforce: true` for that host in configy** (PR-reviewed, picked up by the poll loop, no redeploy).

**Nothing left to build.** Remaining is purely operational/timeline: the 2026-06-08 dry-run review (above), then per-host enforce flips (xwing → salvare → avalon), each lucas42's call after a clean per-host review. (Verify live ticket states before citing — these churn.) salvare confirmed by lucas42 to have no public-facing services (base-only rules in enforce expected). The `firewall_enforce` flip to enforce is lucas42's call per host.

A mandatory `lucos-security` review gate on every `lucos_firewall` PR was added to the code-reviewer workflow this session. Cf. [[firewall-security-gate]] if split out later.
