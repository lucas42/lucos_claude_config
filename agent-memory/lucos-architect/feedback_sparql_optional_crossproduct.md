---
name: SPARQL OPTIONAL chains cross-product on labels
description: Adding a second label OPTIONAL to a SPARQL query that didn't already dedupe will silently multiply rows whenever subjects/objects carry multiple matching labels.
type: feedback
---

When proposing changes to a SPARQL query that adds an additional `OPTIONAL { ... }` clause matching a property that frequently has multiple values per subject (notably `rdfs:label` for multilingual / alternate-name data, but also any other multi-valued labelling predicate), **flag the dedup risk on the consuming code**.

SPARQL processes multiple OPTIONALs as a chain of left-joins. For one base triple `S P O`, the result row count is the product of `max(1, count(matches))` across each OPTIONAL. So adding a second label OPTIONAL on top of an existing one changes the row count from `count(prefLabel)` to `count(prefLabel) × count(rdfsLabel)`. If the consuming JS/template iterates rows and pushes values without deduping, every duplicated row becomes a duplicated rendered value.

**Why:** Hit on lucas42/lucos_arachne#426 → PR #427 (Apr 2026). The original issue body proposed adding `OPTIONAL { ?predicate rdfs:label ?predicateLabelRdfs }` and the symmetric one on the object, without flagging that the existing renderer (`explore/src/server/index.js`, `/item` route) does not dedupe values within a predicate. Result: the London Zoo entity page showed "Contained In Place: London" 6 times — London has 6 `rdfs:label` values across languages, so the SPARQL produced 1×6=6 rows for one triple. The bug was latent pre-#427 (any entity with multiple `skos:prefLabel` values would have triggered it), but #427 turned a corner case into an estate-wide regression because `rdfs:label` is where multilingual data lives.

**How to apply:** When proposing or reviewing any SPARQL change in the lucos estate that adds a label-fetching OPTIONAL to a query whose results feed into a renderer:

1. Identify the consuming code path. Check whether it dedupes rows by `(predicate, object)` or equivalent before pushing values.
2. If it doesn't, flag this in the issue body **before the fix is implemented**, not after — propose either (a) JS-side dedup with "best label across rows" picking, or (b) `GROUP BY` + `SAMPLE` in SPARQL with explicit per-language preference.
3. Same caution applies to any predicate that's plausibly multi-valued: `foaf:name`, `dc:title`, `skos:altLabel`, `mads:variantLabel`. Not just `rdfs:label`.
4. The dedup-by-row-grouping pattern (Map keyed on `(predicate, object)`, then collapse rows to best-label) is the safest default — it doesn't depend on triplestore-specific SPARQL semantics and tests cleanly.

This is a class of mistake to anticipate, not just to learn from once.
