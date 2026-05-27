---
name: check-special-cases-before-extending-pipeline
description: When extending a processing pipeline (e.g. proposing an ancestor walk on top of existing type-deriving logic), check existing special cases in the same function — a naive walk from "the raw input" can silently bypass rewrites the special cases have already applied
metadata:
  type: feedback
---

When proposing to extend a function with a new processing step that walks/looks up data — e.g. "for each rdf:type, walk rdfs:subClassOf and collect ancestor labels" — read the function's existing branches first. If any branch short-circuits or rewrites the upstream value (e.g. searchindex.py's LanguageFamily special case rewriting `doc["type"]` to the literal string "Language"), the new step must start from the post-special-case value, not from the raw input.

Otherwise the new step quietly bypasses the special case's intent. The bug doesn't surface in design review unless someone walks through a specific subject end-to-end mentally.

**Why:** ADR-0004 (lucos_arachne#584, 2026-05-27). My original Phase 2 sequencing text said "walk `rdfs:subClassOf` recursively from the raw `rdf:type`". For a Language subject whose `rdf:type` is a LanguageFamily instance (e.g. `<…/iso639-5/cel>`), the raw walk would produce `types: ["Celtic languages"]` — not `["Language"]`. After Phase 3 ships, `data-types="Language"` silently stops matching languages that belong to families. lucos-code-reviewer caught it pre-merge. The Consequences section of the same ADR claimed `types: ["Language", …]`, which would have been a contradiction with the implementation guidance.

**How to apply:**
- Before writing the Sequencing / Implementation section of an ADR, read the function being extended. List every branch, special case, and short-circuit it contains.
- Write the new step in terms of the *output* of the existing logic, not the input. ("Start from `doc["type"]` post-special-case" rather than "for each `rdf:type` in the graph".)
- Run at least one mental end-to-end for each branch: special-case subject, normal subject, edge-case subject. Verify the new step does what you want for each.
- The Consequences section is a good cross-check — if a Consequences claim doesn't follow from your Sequencing instructions, one of them is wrong.
