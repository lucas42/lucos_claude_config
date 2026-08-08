---
name: pattern-happy-eyeballs-amplifies-syn-loss
description: Node fetch fails at ~510ms with UND_ERR_CONNECT_TIMEOUT = Happy Eyeballs abandoning IPv4 before the 1s SYN retransmit; plus how to scope packet loss to the home link
metadata:
  type: pattern
---

# `UND_ERR_CONNECT_TIMEOUT` at ~510 ms = Happy Eyeballs, not a dead server

Established 2026-08-08 (ops run). Ticket: lucas42/lucos#278. Corroboration on lucas42/lucos_time#348.

**Signature:** a Node service's `fetch` fails with `TypeError: fetch failed`, `cause.code = UND_ERR_CONNECT_TIMEOUT`, at a very tight mode of **508–517 ms** — while a raw `net.connect()` to the same host, milliseconds later, succeeds in ~20 ms.

**Mechanism:** 500 ms is Node's `autoSelectFamilyAttemptTimeout` default. Linux's *first* SYN retransmit is at **~1 s**. So if a single SYN is dropped, Node abandons the IPv4 attempt half a second before the kernel would have recovered it for free. It only bites when the target is **dual-stack** *and* the container's Docker network has **no IPv6 egress** (`ENETUNREACH` in ~3 ms) — with a single address family there is no attempt timer to trip.

**Measured amplification (same 70 iterations, interleaved, live burst):**
```
attemptTimeout=500 (default) : 29/70 fail (41%)
attemptTimeout=3000          :  3/70 fail (4.3%)
autoSelectFamily=false       :  4/70 fail (5.7%)
```
~8x. Underlying loss ~5%.

**Which l42.eu domains are dual-stack is an accident of DNS authoring** — a domain has AAAA iff it is a CNAME to `*.s.l42.eu` rather than an A record. Dual-stack: `staticmedia`, `am`, `media-api`. Single-stack: `ceol`, `seinn`, `configy`, `monitoring`, `private`. So two checks against equally-lossy paths behave completely differently. Re-derive with `dig +short AAAA <domain>`; don't assume.

## Scoping packet loss (the probe discipline that mattered)

- **`ping` is useless against 152.37.104.10 (home NAT) — ICMP is filtered, so you get 100% "loss" with a healthy path.** Always run a control (1.1.1.1 pinged fine at the same moment). Use TCP connect timing instead.
- **SYN loss has a fingerprint:** connect durations cluster at **~1030 ms** and **~3060 ms** (Linux SYN backoff 1 s, 3 s). Anything in those bands = a dropped SYN, not slowness.
- **Scope it by running the same probe to 4 destinations** (target, own public IP, 8.8.8.8, 1.1.1.1). 2026-08-08: xwing-via-home-NAT 9/80 retransmits; avalon-public, Google, Cloudflare all **0/80** ⇒ avalon's transit was clean, the fault was the home WAN link. Confirmed bidirectionally by running it *from* the home LAN, where avalon-public **and** Cloudflare both showed 7/40 while xwing-local showed 0.
- **Independent corroboration beats a second reading of the same probe:** `lucos_backups` logged 72 consecutive `salvare.s.l42.eu: [Errno 110] Operation timed out` 00:09:20Z→08:43:52Z (salvare sits behind the same link) — a completely different subsystem agreeing on the window.

## The bursty-phenomenon trap

Failure rate swung between ~0% and ~41% within minutes. Two A/B runs returned 0/120 and 0/60 and would have "disproved" a real fault. **Interleave the arms within one loop** so every arm sees identical conditions, and don't conclude "not reproducible" from a quiet window — check the alert history for the duty cycle first.

Related: [[reference_avalon_ipv6_bridging]] (which networks have IPv6 egress), [[pattern_probe_measures_then_discards_latency]], [[feedback_verify_check_claim_against_underlying_store]].
