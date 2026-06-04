---
name: reconcile-empty-source-guard
description: A delete-on-absence reconcile loop must guard against an empty-but-non-erroring authoritative source, or it deletes everything
metadata:
  type: reference
---

# Empty source-of-truth is a delete-everything trap in reconcile loops

Any reconcile that **deletes** state based on "this key is absent from the authoritative list" must explicitly guard against the authoritative list being **empty but non-erroring**. An empty list is indistinguishable from "everything was removed", so without a guard the loop wipes the entire store.

**Why:** A `200 OK` with body `[]` passes `raise_for_status()` and is valid JSON — it does *not* trip the outer try/except that catches an outright outage. So "source unreachable" is safe (it raises early), but "source reachable, returns nothing" is the dangerous case that slips through. Caught on `lucos_creds` PR #353 (configy_sync auto-clean, ADR-0001, 2026-06-04): `cleanupRemovedSystems(set())` would have deleted `PORT`/`APP_ORIGIN` for every system until the next good sync.

**How to apply:** When designing or reviewing any sync/reconcile/cleanup that derives a desired set from an external source and deletes the complement:
- Add a guard that **raises** (not silently skips) when the derived set is empty — failing loudly surfaces the anomaly via the schedule tracker / monitoring rather than hiding a wipe.
- Put the guard at the **function** level, not just the caller, so the contract is self-enforcing if the function is reused.
- This is distinct from a full outage (which raises before reaching cleanup) — the empty-body case is its own failure mode.

Relates to [[feedback_verify_path_before_defensive_code]] (this *is* a justified defensive guard — the path is real and reachable) and the "sync-manages-it, sync-cleans-it" scope invariant in `lucos_creds` ADR-0001.
