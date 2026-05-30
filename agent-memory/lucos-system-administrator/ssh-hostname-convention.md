---
name: ssh-hostname-convention
description: Production SSH uses *.s.l42.eu hostnames with user lucos-agent — not *.l42.eu, not lucas
metadata:
  type: feedback
---

Production hosts are reached via `<host>.s.l42.eu` (e.g. `avalon.s.l42.eu`), **not** `<host>.l42.eu`.

- `avalon.l42.eu` → NXDOMAIN. The DNS search domain `s.l42.eu` makes the *short* name `avalon` resolve correctly, but the *full FQDN* `avalon.l42.eu` does not exist.
- Correct full hostname: `avalon.s.l42.eu` (and similarly for other hosts).

**SSH user:** `~/.ssh/config` specifies `User lucos-agent` for `*.s.l42.eu`. Never override with an explicit `user@hostname` using `lucas` or any other username — it bypasses the config and gets rejected.

**Safe pattern:** just `ssh avalon.s.l42.eu` — no explicit username, let the config apply.

**Why:** The SRE agent used `lucas@avalon.l42.eu` during the 2026-05-30 session degradation investigation and got `Permission denied (publickey)` throughout. Both the hostname and the username were wrong. The SSH key itself was fine.

**How to apply:** When instructing any agent to SSH to a production host, always give the full `<host>.s.l42.eu` form and omit the username (let `~/.ssh/config` supply `lucos-agent`). See [[hosts-ipv4-nat]] for the NAT/direct-IP distinction.
