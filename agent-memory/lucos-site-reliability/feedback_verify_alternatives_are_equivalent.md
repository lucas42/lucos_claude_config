---
name: When proposing alternative implementations in an issue, verify each one produces equivalent results
description: Listing two "alternative" fixes in an issue body is a claim that they are semantically equivalent. Verify both — bad alternatives propagate confusion and shape the implementation choice. Concrete case: SPARQL DISTINCT-on-values vs DISTINCT-on-subjects-with-property.
type: feedback
---

When proposing **alternative implementations** in a bug report or design issue, both must produce equivalent results — otherwise I am quietly offering the reader a wrong choice as if it were a stylistic preference. The architect catches this; I should catch it first.

**Why:** 2026-05-10, `lucos_arachne#477` (MCP count_by_property timeout fix). I drafted two "alternative" fix forms in the issue body:

```sparql
# Form A — single query
SELECT (COUNT(DISTINCT ?s) AS ?total) (COUNT(DISTINCT ?val) AS ?withProp)
WHERE { ?s a <type> . OPTIONAL { ?s <prop> ?val } }

# Form B — two queries
SELECT (COUNT(DISTINCT ?s) AS ?total) WHERE { ?s a <type> }
SELECT (COUNT(DISTINCT ?s) AS ?withProp) WHERE { ?s a <type> ; <prop> ?val }
```

I framed both as fine. They are not. Form A's `COUNT(DISTINCT ?val)` counts **distinct property values**, not **subjects-with-property**. For `dcterms:language` (4956 subjects, ~50 distinct language URIs), Form A would return `withProp ≈ 50` against Form B's `4956` — a 100× under-report. The architect flagged this on review.

**The SPARQL-specific gotcha:** in an OPTIONAL block, `?val` is unbound for non-matching rows. `COUNT(?val)` counts non-null bindings (i.e. rows where the OPTIONAL matched) but suffers double-counting when a subject has multiple values. `COUNT(DISTINCT ?val)` counts unique values, not unique subjects-with-property. Neither matches the intended "subjects with property" semantic. To get that in one query you need `COUNT(DISTINCT ?sWithProp)` where `?sWithProp` is bound only when the OPTIONAL matches — which requires a `BIND(?s AS ?sWithProp)` inside the OPTIONAL or similar trick. Two queries are cleaner.

**How to apply:**

- Before listing alternatives in an issue body, run each mentally (or for real, against a small dataset) and confirm they produce the same numbers on a representative property. A 30-second sanity check would have caught this.
- When in doubt about the semantics of a SPARQL aggregate inside an OPTIONAL, default to the two-query form. The "elegance" of a single query is not worth a hidden semantic shift.
- More generally: an alternative I list is a claim of equivalence. Don't list one I haven't verified.
