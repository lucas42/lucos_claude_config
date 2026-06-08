---
name: reference-firewall-dockeruser-scope
description: lucos_firewall's DOCKER-USER DROP polices inter-container traffic, not just external — diverges from ADR-0007; the bridge-nf-call-iptables determinant
metadata:
  type: reference
---

lucos_firewall's generated `DOCKER-USER` chain (main.go `generateIPv4Ruleset`/`generateIPv6Ruleset`) ends in a terminal `-j DROP` with allow rules qualified by **protocol+dport only** (no `-i`/`-o`/source). This means it polices **all** forwarded traffic, including container-to-container — broader than ADR-0007's stated scope ("inter-container controls stay on the Compose-network model"). Confirmed by reading source at `b1296b5` (2026-06-08).

Key mechanism facts (reusable):
- **Docker evaluates DOCKER-USER first**, before its own same-bridge ICC ACCEPT — documented contractual purpose of the chain, not insertion-order luck. So a terminal DROP in DOCKER-USER wins over Docker's container-traffic ACCEPTs. Don't expect Docker's ICC rule to "save" inter-container traffic.
- `ESTABLISHED,RELATED -j ACCEPT` rescues only **return** traffic of already-established flows — never the initial NEW SYN of a fresh inter-container connection.
- **Cross-network (different bridges):** always L3-routed → always hits FORWARD→DOCKER-USER → dropped under enforce if dest port not public. Definite.
- **Same-bridge (same compose stack, e.g. app↔its own Postgres):** traverses FORWARD only if host `bridge-nf-call-iptables=1`. If set, enforce breaks app↔database estate-wide. **Check this sysctl on each host before any enforce flip** — it sizes the blast radius.
- Dry-run does NOT surface this (generates ruleset, drops no packets) — latent until enforce.
- Converse oddity: declaring a port `public` currently also opens it inter-container (allow rule is origin-blind).

**RESOLVED in firewall#14 (merged 2026-06-08):** added `-A DOCKER-USER -i br+ -j RETURN` + `-i docker0 -j RETURN` after the ESTABLISHED/RELATED ACCEPT, before the public-port allow-list. This RETURNs **all** bridge-origin traffic before the DROP — so the firewall now polices **external-origin traffic only**.

Key correction to my original analysis above: `-i` matches **ingress** interface = the **source** container's bridge, regardless of destination. So the RETURN exempts **same-stack AND cross-stack** container traffic alike (cross-stack A`br-aaaa`→B`br-bbbb` is *received* on `br-aaaa`, matches `br+`). The firewall does **not** isolate Compose stacks from each other — only Docker's own ICC/isolation + app-level auth do. My earlier lucos_dns#106 conclusion (cross-bridge config-sync→configy would be dropped) is **reversed** by #14: it would now survive enforce. (Cache fix still the right #106 resolution.)

ADR-0007 Amendment 2 (PR #229) documented #14 but mis-stated the cross-stack consequence as "still dropped" (contradicting its own Decision section) and left a pre-existing `:FORWARD DROP` skeleton error (impl uses `:FORWARD ACCEPT` — Docker owns FORWARD; default-deny lives in INPUT policy + DOCKER-USER terminal DROP). I raised CHANGES_REQUESTED on #229 — but it landed ~2.5 min *after* the unsupervised auto-merge fired, so it held nothing (lesson: a late review gates nothing on unsupervised repos; verify PR open first — persona rule added 2026-06-08). **RESOLVED: lucas42 chose Option A (2026-06-08)** — firewall exempts ALL inter-container traffic (same- and cross-stack), polices external-origin only, does NOT isolate Compose stacks; firewall#14 correct as-is, no code rework. Both ADR-0007 corrections (FORWARD `DROP`→`ACCEPT` skeleton + Amendment 2 cross-stack prose) land in **PR lucos#232** (closes lucos#230; ready, auto-merges on code-reviewer approval). Process notes worth keeping: #229 auto-merged before my CHANGES_REQUESTED → a late review gates nothing on unsupervised repos (persona rule added); team-lead's crossed messages gave two plans (sysadmin-raises-PR vs use-#232) — converged on the later/decisive one (#232 sole PR). Cross-stack security relies on app-level auth (Layer 1), not the firewall. Sysadmin lucos-system-administrator did the original source reading. Consistent with #132: identity integrity must not depend on network topology.
