---
name: current-items-currency-model
description: How lucos_time /current-items derives "currency" (Festival-only), and why media collections are invisible to arachne — durable estate facts behind the weightings festival migration
metadata:
  type: reference
---

# `/current-items` currency model + media collections vs RDF

Verified 2026-07-15 against `origin/main` and live arachne. Durable mechanism facts — re-verify specifics before acting, but the shape is stable.

## lucos_time `/current-items` derives currency from `Festival` ONLY

`src/temporal-matcher.js` matches:
- `DayOfWeek` (by `order`, 1=Mon…7=Sun)
- `Month` (per calendar, via `temporalMonthCode` — handles Hebrew/Chinese/Islamic calendars via Temporal's `withCalendar`)
- `Festival` — current if `day_of_month`/`month` matches **OR** any `FestivalPeriod` matches (additive, both always checked)
- `HistoricalEvent` — **transitively**, via the current festival's `commemorates` FK

Plus contacts items appended in `server.js`.

**A `CreativeWork` can never be current.** Nothing makes CreativeWorks temporal. This is the load-bearing consequence for design: choosing `Festival` vs `CreativeWork` as an entity's eolas type decides whether "when is X current?" is free (add a `FestivalPeriod`) or needs a whole new mechanism in both eolas and lucos_time.

**`/current-items` returns only what IS current.** It cannot answer "is this entity seasonal but out of season right now?" — that requires the full resolvable set plus a current flag. Any out-of-season suppression logic needs that, and it belongs in lucos_time (it owns the calendar), not in consumers reverse-engineering eolas URI shapes.

## The "never current" trap

**Easter (`eolas festival/10`) has no `festivalStartsOn` and no `FestivalPeriod`** — computus isn't a fixed day in any Temporal-supported calendar. So lucos_time can *never* return Easter as current. Sole such case of 41 festivals (2026-07-15).

Any rule shaped "penalise X if not in `/current-items`" therefore breaks permanently for entities with no expressible season. Design must distinguish **"has a known season, we're outside it"** from **"we know nothing about its season"** — and fail safe on the latter. See [[feedback_detector_inverse_failure_mode]].

## Media collections are invisible to the knowledge graph

`lucos_media_metadata_api` **does not emit collections to RDF** — no collection predicate in `rdfgen/`, no `Collection` type in arachne. `collection`/`collection_track` are SQLite tables only (`api/migrations/0001_baseline.sql`).

`lucos_media_import` does **not** populate collections — they are hand-curated (via the metadata manager). So collection membership is **editorial judgement that exists in exactly one place and cannot be re-derived**. Both an argument for migrating semantics onto structured tags (which *do* reach arachne), and a strong argument for mechanically copying membership rather than trying to infer it.

## `about` / `mentions` are the only subject-ish track predicates

Whole of `predicateconfig/registry.go` (the single exhaustive source): `about` and `mentions` are the only general subject relations; `theme_tune`/`soundtrack` are CreativeWork-scoped; `memory` is separate. There is **no** "associated with" relation. Both `about`/`mentions` are `AllowedOrigins: [OriginEolas]` — values must be eolas URIs, so tagging against a concept requires the eolas entity to exist first.

**Albums carry no tags** — just `skos:prefLabel` + track list — and `album` is single-valued. So "inherit the association from the album" is not available as a modelling shortcut.

## arachne counting gotcha

`list_types()` instance counts appear to be **exactly 2× reality** (Track 29,414 vs `count_by_property`'s 14,707; Festival 82 vs `find_entities`' 41). Prefer `count_by_property` / `find_entities` for counts; treat `list_types` numbers as relative, not absolute.
