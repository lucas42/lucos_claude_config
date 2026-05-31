---
name: parse-reference-data-never-handbuild
description: When auditing/diffing against a source of truth (config, registry, schema), parse it from the file — never reconstruct the reference set from memory
metadata:
  type: feedback
---

When an audit or diff compares a dataset against a **source of truth** (a config registry, a schema, a systems list, an allowlist), **extract the reference set programmatically from the actual file** — never hand-type it from memory and diff against your own reconstruction.

**Why:** On lucos_creds#333 (2026-05-31) I audited the creds inventory against configy's `systems.yaml`/`scripts.yaml`/`components.yaml` by hand-building the registry lists from memory, then diffing. The hand-built lists were wrong: I omitted `lucos_creds` (which *is* in systems.yaml) and invented `lentil` as present (it isn't). I published a gap table claiming 3 production-gap items including a spurious `lucos_creds` "self-exemption", then had to post a correction. The diff logic was fine; the **reference data was fabricated**, so every conclusion built on it was suspect.

**How to apply:** For any "X present in store but absent from registry Y" analysis: `grep -oE '^[key-pattern]:' Y.yaml | sed 's/:$//' | sort -u` (or the equivalent parse), build the union with `sort -u`, diff with `comm -23`. Then the diff is only as wrong as the parser, which you can spot-check against a couple of known entries. A hand-typed list has no such check and silently encodes recall errors. Same principle as [[feedback_implementation_surface_code_trace]] (cite file:line evidence, don't extrapolate) and [[feedback_verify_premise_not_just_quotes]] (verify the premise, not just the surface). Also: write computed counts into prose only *after* computing them — don't pre-fill "~91 entries / 56 systems" estimates that then read as verified facts.
