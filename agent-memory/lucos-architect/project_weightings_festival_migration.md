---
name: weightings-festival-migration
description: lucos_media_weightings#266 — plan to drop festival-based collections (Christmas/Hallowe'en/Eurovision) from weighting logic; analysis posted 2026-07-15, awaiting lucas42's decisions
metadata:
  type: project
---

# Festival-collection migration — `lucos_media_weightings#266`

lucas42 filed #266 himself (2026-07-14) asking for a plan to move weighting logic off festival-based collections onto structured `about`/`mentions` + lucos_time `/current-items`, "without losing any of the current functionality". Analysis posted 2026-07-15: [issuecomment-4985399181](https://github.com/lucas42/lucos_media_weightings/issues/266#issuecomment-4985399181). **Status: Awaiting Decision** — 5 open questions to lucas42.

**Why:** he named double counting + hard-to-maintain logic as the motivation. Eurovision currency mechanism explicitly descoped by him (current logic always sets it false).

**How to apply:** the analysis comment is the durable record — read it before doing anything further here. Mechanism facts extracted to [[current-items-currency-model]].

## Findings that reframed the ticket

1. **The out-of-season penalty is the real obstacle.** `christmas` collection does `weighting /= 100` outside December. `/current-items` has *no equivalent* — it only says what IS current. Everything else about the migration is easy; this isn't. Needs a new lucos_time endpoint (resolvable festivals + current flag). Hallowe'en has no such penalty — asymmetry that a uniform model would erase.
2. **The data is nowhere near ready.** Christmas: 37 `about` + 8 `mentions`. Hallowe'en: **1** `about` track. Eurovision: no eolas entity at all. All 3 copies of *Fairytale of New York* are `about`→New York / `mentions`→NYPD with **zero** Christmas link; *The Power of Love* (FGTH) has no tags at all. Migrating today silently drops them.
3. **lucas42's assumption holds but its converse fails.** "`about` Christmas ⇒ Christmas song" — no counter-example found. But **Christmas song ⇏ `about` Christmas** — and that's the *majority* case, not an edge case. This is what a new `associatedWith` predicate is for.
4. **Double counting isn't mainly where the ticket assumes.** `getWeighting` takes a **product over every matching current item**, and in December `/current-items` returns Christmas + December + Nativity (via `commemorates`). "Prettiest Eyes" (`mentions` Christmas + December) = ×400 → outranks a real Christmas song; **the migration widens the gap**. Recommended **`max` instead of product** — fixes it structurally rather than by tuning. Removing the collections does *not* fix this.
5. **Hallowe'en window silently widens** on migration: eolas `festivalperiod/4` = 25 Oct–3 Nov vs code's `day > 25` = 26–31 Oct.
6. **ESC type choice prices the descoped ticket.** `Festival` → currency is one eolas record. `CreativeWork` → needs new machinery in eolas + lucos_time. Recommended Festival. Orphan CreativeWorks `223` (EBU/Eurovision Network, linked from Te Deum via `theme_tune`) and `224` ("Eurovision 2006 (Russia)") already exist — `224` looks like the start of an *editions* model, the right home for the year/country bonus.
7. **Te Deum answer: both predicates, no conflict.** `theme_tune`→EBU is what it *is*; `associatedWith`→ESC is true independently (it's literally the opening fanfare every year) and is the only one that can drive a boost.

## Plan shape (phases 0–5)

0. **Comparison tool first** (lucas42 had it last) — decision-independent, no deps, sizes everything else. Small script in this repo; `all-tracks.py`/`media_api.py` already have the machinery.
1. `associatedWith` predicate (media_metadata_api) + ESC Festival (eolas).
2. **lucos_time endpoint** — resolvable festivals + current flag. The cross-repo blocker.
3. Data: **mechanically** copy collection membership → `associatedWith`. The nuance is already in the membership; re-deriving from lyrics is what loses it. Watch duplicates (3 Fairytales, 2 Power of Loves).
4. Logic: drop collection branches, add penalty, fix composition.
5. Eurovision currency (his separate ticket).

0–2 parallel; 3 needs 1; 4 needs 2+3.

## Open decisions with lucas42

max-vs-product · Hallowe'en window widening · out-of-season penalty for all festivals or Christmas-only · ESC as Festival · predicate name.

**Follow-up tickets NOT yet raised** — deliberately, since the decisions change their shape. Committed on the issue to raising them all once he answers, and sending URLs to the coordinator. Don't let this lapse: see [[feedback_file_followups_during_design]].

## Drive-bys

- **VERIFIED + raised as `lucos_media_weightings#267`** (2026-07-15): dev `MEDIA_API` = prod `media-api.l42.eu`, but the dev key is linked to the **development** media-api → 401 on every call. **Dev weightings can reach no media API at all.** Fix = point `MEDIA_API` at `http://localhost:3002`. **The wrong fix** (re-linking dev→prod) would give a dev system `media-metadata:write` on the production library, and this service PUTs weightings every run. Matters for #266: Phases 3/4 have nowhere to be tested until fixed. Detail in [[creds-client-keys-environment-model]].
- `getWeighting`'s `isEurovision` param is unreachable dead code. **Deliberately NOT ticketed** — Phase 4 deletes those branches. Raise only if lucas42 *rejects* the migration, at which point it becomes a design question (the `eurovision` collection currently does nothing: wire it up or delete it?), not a cleanup.

## ADR home (settled 2026-07-15)

Goes in **`lucos/docs/adr/`** (~0014), not a member repo — it spans four existing systems. Precedent: `lucos` ADR-0005 + ADR-0009 are both media-ecosystem-only cross-system contracts living in `lucos`, each with `Discussion:` → a member repo ticket. Set `Discussion:` to lucas42/lucos_media_weightings#266. Persona rule tightened to resolve the multi-existing-system case.
