---
name: loganne-event-level
description: Design recommendation for the per-event `level` field on loganne event payloads (lucos_loganne#506) — taxonomy awaiting lucas42 sign-off
metadata:
  type: project
---

# loganne per-event `level` field (lucos_loganne#506)

Design recommendation posted on the issue 2026-05-31. Awaiting lucas42's taxonomy sign-off before I draft the ADR (loganne's first → ADR-0001, draft PR per unsupervised-repo rule).

**Why:** lucas42 wants UI viewers to filter out low-interest events (track-finished + weighting-update pairs; monitoring alerts during a suppression window).

**Key design decisions (recommended):**
- **Reject rfc5424** — category mismatch (domain events ≠ operational severities), inverted-ordering footgun, 8 levels overkill for 2 demonstrated tiers, implies alerting semantics loganne lacks.
- Field = optional **named string** from a fixed ordered vocabulary (not raw integer), ordering lives in `src/handleEvents.js` (already shared server/client). Absent → default; present-but-unknown → 400.
- **Default = base tier** so that default-event-level == default-filter-threshold and all current (level-less) events still show. This is the hinge of lucas42's "no change if no sources updated" constraint.
- Filtering is **purely client-side** (server stays dumb, sends all events with level; UI hides below threshold via data-level + CSS body class; localStorage persistence). Rejected a `?level=` query param (YAGNI at ≤10k events).
- **Level does NOT touch webhooks/consumers** — routing is by `type`; level is human-UI-only. No consumer change. Additive optional field.
- Per-event (not per-source) confirmed by the monitoring case: same source emits normal vs low depending on suppression state at emit time.

**Taxonomy — REVISED 2026-05-31 after lucas42 feedback.** He confirmed named strings + core design but: rejected `normal` ("normal to whom?"), wants >2 levels, wants a tier *above* default for the lucos_root#135 homepage-events use-case, and wants the filter in a **query parameter** (bookmarkable/linkable) not localStorage.
- Re-proposed a **newsroom/editorial-prominence axis** (self-defining names, not relative): `detail` < `routine` (default) < `notable` < `headline`. Default `routine` preserves backwards-compat (level-less → routine → all shown). `headline` = lucos_root homepage tier.
- Open steers left to lucas42: keep or cut `notable` (no current producer = dead tier smell); whether to add a second below-default tier (declined to invent one).
- **Reversed my first-proposal calls** honestly: (1) server-side filtering now (view route + per-connection websocket filter, reusing shared comparator in handleEvents.js) instead of "keep server dumb" — because a bookmarkable `?level=` URL + lucos_root iframe embed (`?level=headline`) need it; (2) filter control = navigation to a new `?level=` URL + reload, not localStorage state. GET /events also accepts `?level=` for symmetry.
- **lucos_root#135 makes level a real consumer-facing filter**, not human-UI-only. lucos_root embeds loganne `?level=headline` in an iframe.

**Follow-ups to raise after sign-off:** lucos_monitoring (suppressed-window alerts → `detail`); track-finished/lucos_media_weightings emitter (→ `detail`); which events warrant `headline` belongs in lucos_root#135 scope, not pre-specified.

See [[reference_webhook_consumer_accept_202_enqueue]] for the loganne webhook contract context.
