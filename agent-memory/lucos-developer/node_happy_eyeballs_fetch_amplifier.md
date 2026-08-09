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

**Correction (2026-08-08, post-review of the incident report draft):** an
earlier version of this memory said `lucos_media_seinn` was amplified by
Happy Eyeballs (7 of what was then counted as 24 manufactured alerts). That
was wrong and has been retracted in the incident report itself after
`lucos-architect` challenged it: seinn's `media-manager` check probes
`ceol.l42.eu`, which resolves to **avalon** (seinn's own host) — a path
measured at 0/80 retransmits throughout the incident, so the amplifier
cannot apply there. Seinn's logs confirm it: 74 failures, all `The operation
was aborted due to timeout` at 799–823 ms (its own 800 ms `AbortSignal`
budget), **zero** `UND_ERR_CONNECT_TIMEOUT`. **The confirmed amplified count
is 17, all from `lucos_time`.** Seinn's 74 failures correlate strongly in
time with the incident but the causal mechanism was explicitly *not*
established (lucas42/lucos#280 says so directly) — don't backfill one.
Related open tickets if this resurfaces: lucas42/lucos_media_seinn#583,
lucas42/lucos_media_manager#283 (media_manager has no GC/safepoint logging,
so a stall of this kind currently leaves no evidence behind).

Separately, confirmed still accurate: `lucos_media_seinn` (avalon, no
`networks:` block in its docker-compose.yml — plain default project network,
never declared `enable_ipv6` at all) is covered by **neither** #278 (root
fix scoped to the three networks that *declared* IPv6 and didn't get it
applied — lucos_time_default, lucos_monitoring_default,
lucos_dns_secondary_default) **nor** #279 (detects declared-vs-live
divergence; seinn has no declaration to diverge from) — this part of the
gap analysis holds regardless of the amplifier-attribution correction above.
If asked to implement #278/#279, check whether seinn's exposure is in scope
— as filed it isn't.

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
