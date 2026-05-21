---
name: dont-assume-from-service-name
description: When reasoning about a lucos service's role/protocol/risk profile, read the code first — never infer from the name alone
metadata:
  type: feedback
---

When proposing architectural changes that depend on what a service actually does (protocol, port profile, traffic pattern, risk surface), read its `docker-compose.yml` and `src/` before publishing the proposal. Never extrapolate from the service name alone.

**Why:** On lucos#169 (firewall design, 2026-05-21), I claimed `lucos_time` was an NTP server based on the name. I proposed it needed UDP/123 in the allow-list, host networking for low-latency NTP handling, and possible SRE consultation on a host-mode migration. Lucas42 pushed back. Reality: `lucos_time` is a Node.js HTTP service with no NTP code anywhere — `server.js`, eolas-cache, contacts-cache, service worker frontend. The actual reason it uses `network_mode: host` is IPv6 outbound (commit `2d36838`, April 2024), same story as `lucos_monitoring`. The entire "NTP latency" thread was confabulated from a name.

**How to apply:**
- Before any security/firewall/network proposal that names a specific service, open its `docker-compose.yml` AND glance at its top-level source layout. ~30 seconds per service.
- For multi-service proposals, do this for every service named in the proposal.
- If commit history is relevant (e.g. "why does X use Y?"), use `git log -S "Y" -- file` rather than guessing the rationale.
- Naming conventions in lucos (`lucos_<thing>`) are often domain labels, not protocol labels. `lucos_time` is "things about time" not "the time protocol".

See also: [[check-working-counterexample-first]] for the related habit of running a cheap verification before publishing a structural claim.
