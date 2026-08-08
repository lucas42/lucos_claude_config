---
name: declared-vs-deployed-docker-networks
description: Docker networks silently ignore changed compose config; plus how Node Happy Eyeballs turns a lost SYN into a hard failure only on dual-stack answers
metadata:
  type: reference
---

# Compose network config is declared intent, not deployed reality

**An existing Docker network does not pick up changed `networks:` config on redeploy.** Compose attaches to a same-named network if one exists and (observed behaviour; mechanism not proven at Compose-internals level) does not retrofit changed `enable_ipv6`/IPAM onto it. The deploy reports success. Nothing detects the divergence.

Found 2026-08-08 (lucas42/lucos#278 → raised lucas42/lucos#279): `lucos_time_default` and `lucos_monitoring_default` (avalon) and `lucos_dns_secondary_default` (xwing) all **declare `enable_ipv6: true`** and all run with `EnableIPv6=false`. The declaration landed 2026-05-22 (`lucos_time` commit `5e98dc7`, under `lucos` ADR-0007). The avalon networks were created **2024-04-28 and never recreated** — their subnets (`192.168.16.0/20`, `172.22.0.0/16`) predate the daemon's current `default-address-pools`. Networks that *do* carry declared IPv6 (`lucos_dns_default`, `lucos_backups_default`) were both created 2026-06-08, i.e. after the config changed.

**Resolution (2026-08-08):** lucas42/lucos#278 → recreate the three networks (sysadmin). lucas42/lucos#279 → detection lands **deploy-time in `lucos_deploy_orb`**, on SRE's recommendation; the deciding argument is that only the deploy holds *both halves* of the declared-vs-live comparison at once, since the host has no compose file at all (see [[no-onhost-source-of-truth]]). Estate convention for the Node flag is lucas42/lucos_repos#483, awaiting lucas42.

**Always check live `docker network inspect … EnableIPv6` before citing a network's IPv6 state.** I have now made the compose-file-as-truth error twice: once in lucas42/lucos_backups#307 (cited monitoring/time as IPv6 precedents from their compose files), and the corrected reading here. Creation timestamp is the tell — an ancient `Created` on a network whose compose changed recently means the change never applied.

**ULA + NAT66 egress genuinely works on avalon** (verified with an IPv4 control): a container on `lucos_backups_default` at `fd00:3::2/64`, default route `fd00:3::1`, reached global IPv6 in 5 ms, matching its IPv4 time. avalon daemon: `ipv6: true` + `fixed-cidr-v6`; xwing additionally sets `ip6tables: true`.

# Node Happy Eyeballs: the guillotine needs *two* addresses

`autoSelectFamilyAttemptTimeout` only bites when there are multiple addresses to race. Verified against a blackholed single-address destination: with `autoSelectFamily` either true or false the connection **stays pending and the kernel keeps retransmitting** — no timeout fires. So the hard-failure mode needs **a dual-stack DNS answer AND a dead address family**. Consequences:

- Restoring the missing family is a real root-cause fix (the other leg connects), not a workaround.
- The default value has drifted: **250 ms on Node 22, 500 ms on Node 26**. Don't rely on it; set `--network-family-autoselection-attempt-timeout` explicitly.
- Linux's first SYN retransmit is ~1 s, second ~3 s — any attempt timeout below ~1 s converts a recoverable loss into a hard failure.

# l42.eu is dual-stack by construction, and salvare is IPv6-only

`lucos_dns/sync/config-sync.py:render_systems_zone` emits every service subdomain as a CNAME to `<host>.s.l42.eu`; `s.l42.eu.jinja` emits AAAA for every host with an `ipv6` field in configy `hosts.yaml`. Every host except `aurora` has one — so **every service subdomain is dual-stack**, deterministically, not by accident. Only the **apex** records (`l42.eu`, `lukeblaney.co.uk`) are A-only, because an apex can't be a CNAME and the generator has no AAAA branch there.

**`salvare.s.l42.eu` has no A record at all** (configy gives salvare only `ipv6` + `ipv4_nat`; the template emits A only `if host.ipv4`). Anything that must reach salvare requires working IPv6 egress — "just stop publishing AAAA" is structurally impossible for salvare-hosted systems.

**Caution when checking any of this under packet loss:** a `dig` timeout is indistinguishable from an empty answer. On 2026-08-08 I produced the false claim "28 of 33 service domains lack AAAA" — the near-exact inverse of the truth — until a known-positive control also came back empty and exposed the instrument. Separate ERROR from NO-ANSWER as distinct states, and always run a control. See [[parse-reference-data-never-handbuild]].
