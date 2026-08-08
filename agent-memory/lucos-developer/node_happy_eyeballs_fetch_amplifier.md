---
name: node-happy-eyeballs-fetch-amplifier
description: Node's Happy Eyeballs 500ms default converts a single lost SYN into a hard fetch failure on dual-stack l42.eu targets when the caller has no IPv6 egress
metadata:
  type: project
---

Node's Happy Eyeballs implementation abandons the IPv4 connection attempt after
`autoSelectFamilyAttemptTimeout` (default **500 ms** on Node 26, was 250 ms on
Node 22 — it drifts between releases). Linux's first SYN retransmit lands at
**~1 s**. So on any container that is IPv4-only egress but calling a
dual-stack target (every l42.eu service subdomain is dual-stack by
construction — CNAME to a host record carrying AAAA), a single dropped SYN
becomes a hard `TypeError: fetch failed` / `cause.code =
UND_ERR_CONNECT_TIMEOUT` instead of a ~1s-late success. Measured during the
2026-08-08 incident: 41% failure at the 500ms default vs 4.3% with a 3000ms
budget, against ~5% underlying packet loss — an ~8x amplification. Failure
signature to recognise instantly: modal latency **508–517 ms**, while a raw
`net.connect()` to the same host moments later succeeds in ~20 ms.

**Why:** discovered/analysed in the 2026-08-08 home-link packet-loss incident
(lucas42/lucos#280, PR still draft at time of writing) and lucas42/lucos#278.
The architect's decision on #278: root fix is restoring IPv6 egress on the
affected Docker networks (language-agnostic, fixes it properly); explicit
`NODE_OPTIONS=--network-family-autoselection-attempt-timeout=3000` (or
`net.setDefaultAutoSelectFamilyAttemptTimeout(3000)` at startup) is
defence-in-depth on top, not a replacement — it's Node-only and reduces
rather than eliminates the failure. Do **not** reach for
`autoSelectFamily=false` instead — measured comparably (5.7%) but makes the
outcome depend on resolver ordering, an unverified/fragile property.
**Making the explicit timeout an estate-wide convention was explicitly
flagged by the architect as a separate decision needing lucas42's sign-off,
not yet tracked as of 2026-08-08** — if this comes up again, don't assume
it's decided; check for a tracking issue first.

Also: `lucos_media_seinn` (avalon, no `networks:` block in its
docker-compose.yml — plain default project network, never declared
`enable_ipv6` at all) was one of the two Node services actually amplified in
this incident (7 of the 24 manufactured alerts) but is covered by **neither**
#278 (root fix scoped to the three networks that *declared* IPv6 and didn't
get it applied — lucos_time_default, lucos_monitoring_default,
lucos_dns_secondary_default) **nor** #279 (detects declared-vs-live
divergence; seinn has no declaration to diverge from). If asked to implement
#278/#279, check whether seinn's exposure is in scope — as filed it isn't.

**How to apply:** in any Node lucos service that calls another l42.eu
service via `fetch()` — set the attempt timeout explicitly rather than
inheriting the base-image's Node version default, and log `error.cause.code`
in the catch block (not just `error.message`) — collapsing
`UND_ERR_CONNECT_TIMEOUT` / `ECONNREFUSED` / `ENOTFOUND` into a bare "fetch
failed" string cost hours of the 2026-08-08 investigation
(lucas42/lucos_time#348). Before adding this pattern to a specific service,
check whether the estate-convention decision has landed by then — if it has,
follow it; if not, treat per-service opt-in as reasonable but flag it's
ahead of the convention decision.
