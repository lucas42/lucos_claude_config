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

Fix direction (tracked, **lucas42/lucos_firewall#13**): scope the police-and-DROP to external-origin traffic (match ingress external interface, or RETURN docker-bridge-ingress traffic before the DROP), letting inter-container fall through to Docker's own model. Gates the avalon enforce flip under lucos#182. Surfaced via lucos_dns#106 (config-sync→configy cross-bridge). Sysadmin lucos-system-administrator did the original source reading. Consistent with my #132 stance: identity integrity must not depend on network topology, so we're not relying on inter-container policing as a security boundary.
