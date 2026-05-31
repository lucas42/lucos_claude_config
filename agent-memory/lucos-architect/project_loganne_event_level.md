---
name: loganne-event-level
description: Per-event `level` field on loganne — ADR-0001 SHIPPED (PR #507 merged); impl tracked in #510, emitters #270/#238 blocked on it
metadata:
  type: project
---

# loganne per-event `level` field (lucos_loganne#506)

**Status 2026-05-31 — DONE (design phase):** taxonomy signed off; **ADR-0001 merged** (PR #507, merge commit `7456984`, ADR on `main`); #506 auto-closed completed. Follow-ups raised & handed to coordinator for triage:
- **lucas42/lucos_loganne#510** — implement the `level` field (validation + shared comparator + `/view`, `GET /events`, per-connection `/stream` filtering). **Ready.** #506's scope was "ADR **and implementation**", but `Closes #506` orphaned the impl on ADR merge — #510 carries it forward.
- **lucas42/lucos_monitoring#270** — `monitoringAlertSuppressed` event → `level: detail`. **Blocked on #510.**
- **lucas42/lucos_media_weightings#238** — `weightings` event (`all-tracks.py`) → `level: detail`. **Blocked on #510.**
- **track-finished is NOT a real loganne event** — nothing in the estate emits it (manager emits `deviceSwitch`/`fetchTracks`/`collectionSwitch`). The #506 example was inaccurate; filed no ticket. Only `weightings` is a real churn event.
- `headline` taxonomy stays owned by lucos_root#135 — no new ticket.

**Lessons this session:** (1) loganne is **SUPERVISED** (`check-unsupervised` exits 1) despite #506 body + brief saying "unsupervised → draft PR" — opened a normal PR; never trust an issue body's supervised claim, always run `check-unsupervised`. (2) The blocking `test` failure was a **pre-existing time-bomb** (fixed `2026-05-22` date read back through `GET /events`'s 7-day window) — investigated rather than re-triggering; fixed via #508/#509, rebased #507. lucas42's approval survived the force-push (full-SHA-verified).

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

**Follow-ups — RAISED (see Status section at top):** #510 (impl), #270 (monitoring), #238 (weightings). track-finished turned out not to be a real loganne event. `headline` stays with lucos_root#135.

See [[reference_webhook_consumer_accept_202_enqueue]] for the loganne webhook contract context.
