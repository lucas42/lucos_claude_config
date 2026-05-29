---
name: indexability-exclusion-vs-inclusion
description: arachne search indexer decides "is this subject indexable?" by exclusion (meta-type denylist) which ALREADY implements error-on-ambiguity (loud fail + stale fallback); inclusion-as-default was proposed (#590) and REJECTED by lucas42 because it silences the dangerous failure mode
metadata:
  type: reference
---

# Indexability: exclusion (error-on-ambiguity) vs inclusion — RESOLVED, keep exclusion

The arachne ingestor (`ingestor/searchindex.py`, `graph_to_typesense_docs`) decides which RDF subjects become Typesense docs by *exclusion*: index any subject with a `skos:prefLabel` unless its `rdf:type` is a meta-type (`is_meta_type` → `META_NAMESPACES` namespace match + a couple of explicit eolas exceptions).

## Verified mechanism (traced 2026-05-29, not from ticket prose)

For a labelled subject the type loop resolves to one of three branches:
1. **Registered meta-type** → `continue`; `doc["type"]` stays `None`; the final `if doc["type"] and doc["pref_label"]` guard drops it. Silently not indexed — correct.
2. **Domain type with prefLabel + `eolas:hasCategory`** → indexed.
3. **Neither** (not in `META_NAMESPACES`, missing label or category) → `get_label`/`get_category` **raises `ValueError` → ingest crashes loudly.**

**Branch 3 IS an "error on ambiguity" alert** — and it's the loud-fail-with-stale-fallback behaviour the design intends. The recurring outages (#543 `owl:AsymmetricProperty` 14h; lucos_media_metadata_api#271 `skos:Concept`/`ConceptScheme`; #371 origin) were all branch 3 firing: a new meta-type wasn't registered, got misclassified as domain, and the domain-side label/category lookup raised. Each fix = declare it (`META_NAMESPACES` entry) or add the missing `eolas:hasCategory`. That's the control loop working, not a bug.

## #590 (inclusion-as-default) — proposed by me, REJECTED, closed not-planned 2026-05-29

I proposed driving indexability by `eolas:hasCategory` presence (allowlist) to "close the open denylist set." lucas42 pushed back on the premise and was right. Inclusion-as-default converts branch 3 from a loud crash into a **silent skip**:
- For a meta-type that was never meant to be indexed → silent-skip is coincidentally correct (no outage).
- For a genuine **domain type that forgot its `eolas:hasCategory`** → **silently dropped from search, no crash, no alert.** This is the dangerous direction: a missing search document is far harder to notice than a failed ingest. My proposal would have removed the loud signal on the one failure that needs it, to suppress loud signals on failures that are already cheap and self-announcing.

When lucas42 asked for a counter-example where the denylist failure was *not* caught by alerting / was worse than stale-fallback+alert: **I had none.** All cited incidents were loud, diagnosed, fixed — his model working. The #543 14h figure is response-latency, not an alerting failure; inclusion wouldn't have shortened it.

## Lesson (corrects the earlier "denylists drift, prefer positive definition" framing)

A denylist that fails **loud** (crash + stale fallback + alert, low blast radius) is not automatically worse than a positive-definition allowlist. The question isn't "open set vs closed set" — it's **which failure direction is silent.** "Error when the data is ambiguous" is a feature: it never silently does the wrong thing, it only loudly refuses. Before proposing to invert a classification default, trace what each candidate default does in the *forgot-to-declare* case on **both** sides, and prefer the one whose failure is loud for the dangerous case. Recurrence of the same loud, cheap incident shape is a working feedback loop, not proof the design is wrong — pressure-test against [[feedback_check_value_when_fix_complexity_grows]] and proportionality before "closing the set."

The only orthogonal kernel left (NOT pursued): the *redeploy friction* of declaring a new meta namespace (code change + deploy each time) could be cut with a data-driven `META_NAMESPACES` registry **without** losing error-on-ambiguity. Correctness-neutral ergonomics; incident rate too low to justify pre-emptively. lucas42's call if friction ever bites.

Related:
- [[feedback_apply_frame_review_to_own_reasoning]] — this was a textbook case: I was anchored on "open set → close it" and missed that the code already implemented his preferred model
- [[feedback_verify_ci_mechanism_before_relying_on_it]] — verify the mechanism (here: trace the actual branches) before designing around it
- [[feedback_check_special_cases_before_extending_pipeline]] — the special cases (LanguageFamily→Language, per-subject PlaceType category, subClassOf walk) sit between raw rdf:type and resolved domain type
- [[feedback_data_driven_over_code_rules]]
