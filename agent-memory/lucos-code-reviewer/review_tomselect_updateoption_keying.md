---
name: review-tomselect-updateoption-keying
description: tom-select updateOption(value, data) keys by the FIRST argument, which must match valueField — passing a different field silently no-ops
metadata:
  type: project
---

In `lucos_search_component`'s `web-components/lucos-search.js`, TomSelect's internal `options` object is keyed by `data[settings.valueField]` (set in `addOption`). `updateOption(value, data)` looks up `self.options[hash_key(value)]` using its **first** argument as the key — if that key doesn't match an existing option, it returns early with **no error, no warning** (`if (data_old == undefined) return;` in tom-select v2.4.3 source).

**Why this matters:** any code path that calls `updateOption(someField, result)` must key on the *same* field as `valueField`, not just "the field that seems like the natural id" (e.g. `result.id`). If `valueField` is conditional (e.g. `contact_uri` in contact mode, `id` otherwise — see lucas42/lucos_search_component#189/#190), every `updateOption` call site in the file must branch the same way, not just the query/filter that fetches the data.

**Confirmed bug:** lucas42/lucos_search_component PR #190 correctly branched the `filter_by` query to `contact_uri` in contact mode (`onInitialize`'s pre-selected-item refetch), but left `this.updateOption(result.id, result)` unbranched. In contact mode this silently no-ops, so a page-load pre-selected contact-mode item is never hydrated — its `onItemSelect` click-through then falls back to the raw form value (`contact_uri`), reopening the exact "wrong URL" bug the PR was meant to fix, just for the pre-selected/edit-form case rather than fresh search-and-select.

**How to apply:** whenever a PR to this component changes `valueField` conditionally, grep the whole file for `updateOption(`, `addOption(`, and any `.id`/`.map`/`.filter`/`.has(` used against TomSelect's options map or a `commonSet`/`preloadedIds` dedup set — verify every one branches the same way as `valueField`. Also check `_commonOptions`/`_preloadedOptions` hydration blocks — same latent issue if `data-common`/`data-preload` are ever combined with `data-is-contact`.

**Fix landed (PR #190, commit 79ffc63):** a `get valueFieldName()` getter (`isContactMode ? 'contact_uri' : 'id'`) is now the single source of truth, used everywhere the code reads/writes TomSelect's options map — `create()`, `valueField`, the `commonSet` dedup in both `load` and `onFocus`, the common/preload `filter_by` queries, and all three `updateOption` call sites (main refetch + both pre-selected common/preloaded refresh blocks). The literal `data.id`/`option.id` was correctly *kept* in `render.item`/`render.option`/`onItemSelect` — those are the semantic lozenge-link target, not the TomSelect key, and must NOT be routed through `valueFieldName`. When reviewing future changes here, check that this distinction (TomSelect internal key vs. semantic entity id) is preserved — collapsing them back together would be a regression.

**Test-plan gap to watch for:** manual E2E verification that only exercises a *fresh* search-and-select does not exercise the `onInitialize` hydration path at all — a page-load-with-pre-selected-item pass is a separate scenario that must be tested explicitly.
