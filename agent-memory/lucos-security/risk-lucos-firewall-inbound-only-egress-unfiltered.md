---
name: risk-lucos-firewall-inbound-only-egress-unfiltered
description: lucos_firewall (ADR-0007) only filters inbound traffic on avalon/xwing/salvare — outbound/egress is deliberately OUTPUT ACCEPT for both IPv4 and IPv6, by design, not an oversight.
metadata:
  type: project
---

`lucos_firewall` (single-file Go service, `network_mode: host`, `cap_add: NET_ADMIN`, deployed enforcing on avalon/xwing/salvare per lucas42/lucos#182) manages `iptables` **and** `ip6tables` — but only the `INPUT` and `DOCKER-USER` chains. Neither `generateIPv4Ruleset()` nor `generateIPv6Ruleset()` in `main.go` ever declares an `OUTPUT` rule; `:OUTPUT ACCEPT` is left as Docker/host default.

This is deliberate, documented policy in **ADR-0007** (`lucas42/lucos/docs/adr/0007-estate-wide-default-deny-port-policy.md`), not a gap:
- Scope: "everything outbound stays accepted (`OUTPUT ACCEPT`)."
- Out of scope, explicitly: "Per-service outbound restrictions would be a different ADR with a different cost/benefit balance."
- IPv6 gets the *same treatment* as IPv4 — a parallel `ip6tables` ruleset, same allow-list — i.e. inbound-only coverage for both families, not an IPv6 exemption.

**Structural reinforcement:** `DOCKER-USER`'s `-i br+ -j RETURN` / `-i docker0 -j RETURN` rules (ADR-0007 Amendment 2, 2026-06-08) return ALL bridge-interface traffic — including container-originated egress, since the ingress interface for an egress packet is the container's own bridge — straight back to Docker's `FORWARD ACCEPT` before it ever reaches the inbound allow-list logic. So container egress bypasses lucos_firewall's logic structurally, not just via an unpopulated rule.

**Why this matters:** any future security review of a Docker network gaining a *new address family* for egress (e.g. lucas42/lucos#278 — restoring `enable_ipv6` on `lucos_time_default`/`lucos_monitoring_default`/`lucos_dns_secondary_default`) is **not** a meaningful posture change from a filtering-control standpoint — there was no filtered IPv4 egress path being "matched" by the new IPv6 one; both are and always were wide open. Don't treat "container gains a second egress path" as inherently a new risk without checking whether *any* egress path was ever filtered to begin with — verified here that none was.

**Precedent:** `lucos_backups` already rides this exact pattern (bridged onto an `enable_ipv6` ULA network `fd00:3::/64` with NAT66 egress, per lucos#182 regressions-found item 4) — established well before #278, uncontroversially.

**Gap worth flagging if reviewing #278 or ADR-0007 again:** neither document states outright "outbound IPv6 is intentionally as unfiltered as outbound IPv4" — it has to be assembled from `OUTPUT ACCEPT` + the `DOCKER-USER` RETURN mechanism. Suggested (non-blocking) — one clarifying sentence in either doc.

See also [[lesson-silent-vs-loud-guards]] — a security-relevant *absence* of a control that's easy to mistake for coverage because the same tool does cover the adjacent (inbound) case.
