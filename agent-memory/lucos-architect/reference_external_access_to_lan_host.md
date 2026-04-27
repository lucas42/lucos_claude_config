---
name: External access to a LAN-only host — three patterns and their trade-offs
description: When a host on a private LAN needs to be reachable from a remote system, the design choice is roughly: public IPv6, encrypted tunnel (WireGuard), or SSH ProxyJump via a gateway. Each has distinct security and code-complexity profiles.
type: reference
---

When designing a path between a remote system (e.g. a VPS) and a host on a private LAN (e.g. a home NAS), the realistic options reduce to three patterns. Picking the right one is *primarily a security decision*, not a connectivity one — the connectivity bit usually has multiple workable answers.

### Pattern 1 — Public IPv6 with strict allowlist firewalling

Give the LAN host a public IPv6 GUA, then firewall everything that listens on it down to "the one thing we want". Router-level firewall (allowlist) plus host-level firewall (defence in depth).

- **Security:** medium. Workable but requires diligent firewalling at two layers; one misconfiguration and the host is internet-facing. Worse on devices with a poor security track record (QNAP, ageing routers, anything that ships with multiple listening services by default).
- **Code complexity:** low. The host appears in config like any other; the application doesn't know it's special.
- **Operational risk:** ongoing — every firmware update or router config change is a chance to lose the firewall rules.
- **Verification:** require an external port scan from off-LAN before treating it as secure. "I think the firewall is on" is not enough.

### Pattern 2 — Encrypted tunnel (WireGuard typically)

Stand up a WireGuard tunnel; the LAN host or a gateway on its LAN runs the WireGuard endpoint. The remote system gets a private tunnel address that routes to the LAN host directly.

- **Security:** high. Zero ports exposed to the public internet. WireGuard is silent to scanners (no response to probes without a valid handshake). Tunnel is mutually authenticated and encrypted at the network layer.
- **Code complexity:** low. Once the tunnel is up, the LAN host is reachable by name like any other host. No application-layer changes needed.
- **Operational risk:** low for steady-state; setup is more involved (key management, persistent tunnel, MTU considerations on some networks).
- **Variations:** WireGuard endpoint on the LAN host itself if its firmware supports it (cleanest). Or WireGuard endpoint on a Linux box on the same LAN, routing the LAN subnet over the tunnel. The latter works for any LAN host, including ones whose firmware doesn't speak WireGuard.

### Pattern 3 — SSH ProxyJump via a gateway

The remote system SSHes to a gateway host on the LAN, then the gateway proxies the SSH session onward to the target host.

- **Security:** high (no new internet exposure beyond what the gateway already has). Authentication is reused from existing SSH key infra.
- **Code complexity:** **medium-to-high if not already in place.** Requires every outbound SSH/SCP path in the application to honour the gateway flag. Centralising those calls is required to avoid partial-application bugs (see `feedback_check_history_before_proposing_ssh.md`).
- **Operational risk:** the gateway is a SPOF for the target. If it's already a critical host (and so already a SPOF for other things), adding this exposure is not new risk.
- **Sweet spot:** when the application already has all outbound SSH funneled through a single helper. If it doesn't, the centralisation refactor is part of the cost.

### How to choose

In rough preference order for a security-sensitive host:

1. **Tunnel (Pattern 2)** if the LAN host or a same-LAN Linux box can run a WireGuard endpoint. Lowest exposure, lowest code-complexity, highest security.
2. **ProxyJump (Pattern 3)** if a suitable gateway already exists AND the application's outbound SSH paths are (or are willing to be) centralised. Avoids any new internet exposure.
3. **Public IPv6 with allowlist (Pattern 1)** as the pragmatic last resort if neither tunnel nor ProxyJump is feasible. Accept the ongoing operational risk and verify with external port scans.

### Anti-patterns

- Recommending public IPv6 exposure as the *primary* design without security input — always route through security review first.
- Splitting the centralisation refactor (Pattern 3 prerequisite) and the gateway-using feature into separate PRs — they must land atomically or partial application bites (see PR #160 / issue #185 in lucos_backups, April 2026).
- Mixing patterns "for redundancy" — e.g. exposing IPv6 *and* having a tunnel as fallback. Doubles the attack surface for no clear benefit; pick one.

### Application to lucos environment

The home NAS (aurora) sits behind xwing on RFC1918 LAN. xwing has been the gateway/relay for salvare in the past. The realistic options for any "remote service needs to write to aurora" requirement map directly onto the three patterns:

- WireGuard endpoint on aurora itself (if QTS 5.1+) → Pattern 2 (cleanest)
- WireGuard endpoint on xwing routing the LAN subnet → Pattern 2 (almost as clean)
- ProxyJump via xwing's existing SSH infra → Pattern 3 (works if outbound SSH is centralised first)
- IPv6 on aurora with strict v6 ACLs → Pattern 1 (last resort, requires careful firewalling)
