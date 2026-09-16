---
name: loganne-event-level
description: Per-event `level` field on loganne — SHIPPED and live in production; taxonomy detail < routine < notable < headline, default routine
metadata:
  type: project
---

# loganne per-event `level` field — DONE

**Status 2026-09-16 — shipped and live.** ADR-0001 merged in `lucos_loganne` (PR #507); implementation lucas42/lucos_loganne#510, lucas42/lucos_monitoring#270 and lucas42/lucos_media_weightings#238 all closed-completed (re-fetched 2026-09-16). Verified in production: `GET /events` carries `level` on every event.

**Taxonomy as shipped:** `detail` < `routine` (default) < `notable` < `headline`. An editorial-prominence axis with self-defining names, deliberately *not* rfc5424 severities — domain events aren't operational severities, and rfc5424's inverted ordering is a footgun. Absent → `routine`, so level-less events still show; present-but-unknown → 400.

**The open steer resolved itself.** I flagged `notable` at design time as a possible dead tier — no producer, and a tier nobody emits is a smell. It now has one: `lucos_arachne`'s `knowledgeIngest` uses it for partial failures ("some sources failed"). Observed distribution in a week of production events is `routine` 322, `notable` 1, which is the shape you'd want — the non-default tiers are rare by construction, not unused.

**Design points worth not rediscovering:**
- Filtering is **server-side** (`?level=` on `/view`, `GET /events`, and per-connection stream filtering), reversing my first proposal of a dumb server plus client-side CSS. The deciding constraint was that a bookmarkable/linkable URL and lucos_root's `?level=headline` iframe embed both need the server to filter.
- **Level does not touch webhooks or consumers** — routing is by `type`. It is a presentation axis, additive and optional.
- Per-event, not per-source: the same source emits different levels depending on state at emit time (monitoring's suppression window was the case that settled it).
- `headline` is owned by lucas42/lucos_root#135, not by loganne.

See [[reference_webhook_consumer_accept_202_enqueue]] for the loganne webhook contract, and [[loganne-wire-format-gotchas]] for payload-shape traps in `GET /events`.
