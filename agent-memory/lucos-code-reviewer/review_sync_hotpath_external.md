---
name: review-sync-hotpath-external
description: Flag synchronous external-service calls wired into track-save / write hot paths — missing timeout or fallback is a blocking issue
metadata:
  type: feedback
---

When a PR adds a resolver, name-lookup, or any HTTP call to an external service **synchronously in a write or request hot path** (e.g. inside `updateTagsV3`, a POST handler, or any function called directly from an HTTP request):

1. **Check for a timeout + fallback.** If the call can hang indefinitely (no short deadline, no accept-and-reconcile-later logic), flag it as REQUEST_CHANGES.
2. **Check that the call is actually necessary in the hot path.** Create-on-the-fly resolvers belong in background workers or async reconcilers, not synchronous request paths.

**Why:** `lucas42/lucos_media_metadata_api#274` wired `ResolveNameToURI` / `ResolveURIToName` into `updateTagsV3` synchronously. eolas's bulk endpoint slowed to ~23s; every composer/producer save hung → 502. Real-world outage 2026-05-29 (incident report: `lucas42/lucos#202`/`#203`).

**How to apply:** On any PR that adds a new `ResolveNameToURI` / `ResolveURIToName` resolver to a predicate config (or similar pattern in other services), read the call site and ask: what happens if the external service takes 30s or errors? If the answer is "the user's request hangs/errors", flag it.

**Companion smell — `fetchEolasName` → whole-dataset fetch:** In `lucos_media_metadata_api`, `fetchEolasName(uri)` is implemented as `fetchEolasNames([uri])`, which fetches the **entire eolas dataset** to resolve a single name. Any code path that calls `fetchEolasName` per-save thus has O(dataset) latency. Flag this pattern if encountered in new code.
