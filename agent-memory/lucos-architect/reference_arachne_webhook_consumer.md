---
name: reference-arachne-webhook-consumer
description: arachne consumes Loganne events via a webhook in ingestor/server.py — dispatches by event-name SUFFIX (Created/Added/Updated/Deleted/Merged), not exact match. It is NOT pull-only. The scheduled ingest is bootstrap/recovery; the webhook is steady-state.
metadata:
  type: reference
---

# arachne is event-driven, not pull-only

`lucos_arachne/ingestor/server.py` contains a webhook handler at `POST /webhook` that consumes Loganne events from the estate. It dispatches by the **suffix** of `event.type`, not by the full event name:

```python
if event_type.endswith("Created") or event_type.endswith("Added") or event_type.endswith("Updated"):
    fetch_url(event["source"], event["url"])
    replace_item_in_triplestore(event["url"], live_systems[event["source"]], content, content_type)
    update_searchindex(event["source"], content, content_type)
elif event_type.endswith("Deleted"):
    delete_item_in_triplestore(...)
    delete_doc_in_searchindex(...)
elif event_type.endswith("Merged"):
    merge_items_in_triplestore(event["sourceUri"], event["targetUri"], ...)
    delete_doc_in_searchindex(event["source"], event["sourceUri"])
    fetch_url(event["source"], event["targetUri"])
    replace_item_in_triplestore(...)
    update_searchindex(...)
```

So arachne effectively consumes any event in the estate whose name ends in one of those five suffixes. From contacts: `contactCreated`, `contactUpdated`, `contactDeleted` (plus the new `contactLinked`/`contactUnlinked` after lucas42/lucos_arachne#540). From eolas: `itemCreated`, `itemUpdated`, `itemDeleted`, `entityMerged` (→ `itemMerged` after lucas42/lucos_eolas#254). From media: all the `track*`/`album*`/`collection*` events including `albumMerged`.

The scheduled ingest in `ingestor/ingest.py` is the bootstrap/recovery path — not the steady-state mechanism.

## Implications for design advice

- **Layer 2 staleness is seconds, not hours/days.** Don't frame lazy-lookup as a long-staleness fallback. Webhook → refetch → Typesense write is fast.
- **New event suffixes must be added to the dispatch list.** When proposing a new operation-verb event (e.g. `Linked`, `Unlinked`), check arachne's suffix list — unrecognised suffixes are silently dropped. File a co-deploy ticket on arachne if a new suffix is needed.
- **"Trigger re-ingest on event X" is not a meaningful design question** — arachne already does that for any event with a recognised suffix. The real question is "does single-URL refetch correctly recompute the affected document?" (especially for `owl:sameAs` closures where one refetch may need to update multiple documents).

## How I got this wrong (2026-05-17)

I greped `*.py` for `loganne|Loganne|updateLoganne` and found only the **emitter** sites (`compact.py`, `ingest.py`). I concluded "arachne is pull-only" and stated it confidently in design advice. The consumer (`server.py`) doesn't grep for `loganne` because it receives webhooks, not calls `updateLoganne`. lucas42 caught the mistake.

The general lesson is in [[feedback_grep_and_conclude_anti_pattern]].

Cross-ref: [[reference_arachne_ingestor_inverse_materialisation]] (separate concern about owl:inverseOf bloat).
