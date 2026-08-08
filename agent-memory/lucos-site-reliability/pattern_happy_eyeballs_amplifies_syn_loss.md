---
name: pattern-happy-eyeballs-amplifies-syn-loss
description: Node fetch fails at ~510ms with UND_ERR_CONNECT_TIMEOUT = Happy Eyeballs abandoning IPv4 before the 1s SYN retransmit; plus how to scope packet loss to the home link
metadata:
  type: pattern
---

# `UND_ERR_CONNECT_TIMEOUT` at ~510 ms = Happy Eyeballs, not a dead server

Established 2026-08-08 (ops run). Ticket: lucas42/lucos#278. Corroboration on lucas42/lucos_time#348.

**Only bites when the target is dual-stack AND the caller has no IPv6 egress** — with a single address family there is no race, the attempt timer never fires and the kernel's retransmit does its job (verified by lucos-architect: single-family blackholed dest still pending at 6000ms either way). Node default drifted 250ms (v22) -> 500ms (v26), so set it explicitly rather than inheriting.

**Signature:** a Node service's `fetch` fails with `TypeError: fetch failed`, `cause.code = UND_ERR_CONNECT_TIMEOUT`, at a very tight mode of **508–517 ms** — while a raw `net.connect()` to the same host, milliseconds later, succeeds in ~20 ms.

**Mechanism:** 500 ms is Node's `autoSelectFamilyAttemptTimeout` default. Linux's *first* SYN retransmit is at **~1 s**. So if a single SYN is dropped, Node abandons the IPv4 attempt half a second before the kernel would have recovered it for free. It only bites when the target is **dual-stack** *and* the container's Docker network has **no IPv6 egress** (`ENETUNREACH` in ~3 ms) — with a single address family there is no attempt timer to trip.

**Measured amplification (same 70 iterations, interleaved, live burst):**
```
attemptTimeout=500 (default) : 29/70 fail (41%)
attemptTimeout=3000          :  3/70 fail (4.3%)
autoSelectFamily=false       :  4/70 fail (5.7%)
```
~8x. Underlying loss ~5%.

**⚠️ CORRECTED same day — I got this backwards first time.** **EVERY l42.eu service subdomain is dual-stack, deterministically.** `lucos_dns/sync/config-sync.py:render_systems_zone` emits every service subdomain as a CNAME to `<host>.s.l42.eu`, and `s.l42.eu.jinja` emits an AAAA for every configy host with an `ipv6` field (all but `aurora`). Only the **apex** names (`l42.eu`, `lukeblaney.co.uk`) are A-only — an apex can't be a CNAME. Verified authoritatively: `ceol`/`seinn`/`configy`/`monitoring`/`backups`/`repos`/`private` are all CNAMEs to `avalon.s.l42.eu` or `xwing.s.l42.eu`, both of which carry AAAA.

**How I got it wrong, because the failure is subtle:** `dig +short AAAA <domain>` from the sandbox during the packet loss. A CNAME'd name needs the resolver to chase into `s.l42.eu` — a second round trip over the lossy link — and when that timed out `+short` printed **nothing**, byte-identical to a legitimate "no AAAA". Two domains' chains happened to complete, so the output was a **plausible mix (5 yes / 5 no), not uniform silence** — and I then invented "an accident of DNS authoring" to explain the pattern. A plausible mix defeats the usual "suspect a uniformly-negative probe" instinct. **Rule: for any DNS claim, query the AUTHORITATIVE server (`dig +tcp @178.32.218.44 …` for l42.eu) and run a known-negative control** — the recursive path returned `NOERROR` for a nonexistent name that day, which is impossible and would have condemned the run in one line. lucos-architect independently made the same false negative twice the same afternoon.

**The real trigger** was not DNS at all: `lucos_time_default` and `lucos_monitoring_default` (and `lucos_dns_secondary_default` on xwing) have declared `enable_ipv6: true` since 2026-05-22 (commit `5e98dc7`, ADR-0007) and it **never took effect** — Compose reuses an existing network and doesn't retrofit changed attrs; those two were created 2024-04-28. So `EnableIPv6=false` was unapplied config, NOT settled intent (I had cited my own lucos_backups#307 note as if it were a decision). Tracked as lucas42/lucos#279; I recommended deploy-time detection in `lucos_deploy_orb`, which is the only place holding both the compose file and a Docker connection to the host.

## Scoping packet loss (the probe discipline that mattered)

- **`ping` is useless against 152.37.104.10 (home NAT) — ICMP is filtered, so you get 100% "loss" with a healthy path.** Always run a control (1.1.1.1 pinged fine at the same moment). Use TCP connect timing instead.
- **SYN loss has a fingerprint:** connect durations cluster at **~1030 ms** and **~3060 ms** (Linux SYN backoff 1 s, 3 s). Anything in those bands = a dropped SYN, not slowness.
- **Scope it by running the same probe to 4 destinations** (target, own public IP, 8.8.8.8, 1.1.1.1). 2026-08-08: xwing-via-home-NAT 9/80 retransmits; avalon-public, Google, Cloudflare all **0/80** ⇒ avalon's transit was clean, the fault was the home WAN link. Confirmed bidirectionally by running it *from* the home LAN, where avalon-public **and** Cloudflare both showed 7/40 while xwing-local showed 0.
- **Independent corroboration beats a second reading of the same probe:** `lucos_backups` logged 72 consecutive `salvare.s.l42.eu: [Errno 110] Operation timed out` 00:09:20Z→08:43:52Z (salvare sits behind the same link) — a completely different subsystem agreeing on the window.

## The bursty-phenomenon trap

Failure rate swung between ~0% and ~41% within minutes. Two A/B runs returned 0/120 and 0/60 and would have "disproved" a real fault. **Interleave the arms within one loop** so every arm sees identical conditions, and don't conclude "not reproducible" from a quiet window — check the alert history for the duty cycle first.

Related: [[reference_avalon_ipv6_bridging]] (which networks have IPv6 egress), [[pattern_probe_measures_then_discards_latency]], [[feedback_verify_check_claim_against_underlying_store]].
