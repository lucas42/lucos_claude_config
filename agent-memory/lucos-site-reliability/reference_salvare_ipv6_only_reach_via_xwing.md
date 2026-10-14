---
name: reference-salvare-ipv6-only-reach-via-xwing
description: salvare.s.l42.eu has only an AAAA record; when the agent sandbox lacks global IPv6, ssh fails "Could not resolve hostname" — use ssh -J xwing.s.l42.eu salvare.s.l42.eu
metadata:
  type: reference
---

`salvare.s.l42.eu` is IPv6-only: the authoritative server (`dig +tcp @178.32.218.44`) returns an AAAA record and no A record. The agent sandbox sometimes has only a ULA IPv6 address (`fdf9:…`) and no global route. When that happens, `ssh salvare.s.l42.eu` fails with `Could not resolve hostname … No address associated with hostname`. That error is AI_ADDRCONFIG filtering out the AAAA, not a DNS outage. It worked earlier the same night (2026-10-14), so the sandbox's IPv6 comes and goes.

**How to apply:** use `ssh -J xwing.s.l42.eu salvare.s.l42.eu` (verified 2026-10-14). Don't use `salvare-v4.s.l42.eu`: it's a deploy route that lands on xwing ([[pattern_s_l42_eu_v4_names_are_not_host_aliases]]). Before blaming DNS, check `dig +tcp @178.32.218.44 salvare.s.l42.eu AAAA` and `curl -6`.

Related: during a large `create-backups` run, the home uplink saturates and the sandbox's long, quiet SSH sessions (e.g. sha256 of multi-GB files) drop with `client_loop: send disconnect: Broken pipe`, even with ServerAliveInterval set. Do checksums after the run finishes.
