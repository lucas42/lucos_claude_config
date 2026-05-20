---
name: review_js_async_mutex
description: Sibling-function mutex asymmetry is a high-signal code smell in JS service-worker / async code — if one state-modifier has a mutex and a related one does not, flag it.
metadata:
  type: feedback
---

**When reviewing JS async code (especially service-worker code using `forEach(async ...)` or other implicit parallelism), treat sibling-function mutex asymmetry as a high-signal smell.**

If a function that *reads and writes shared mutable state* has a serialising mutex (e.g. `evictionLock`) and a closely related state-update function does NOT, the unprotected function is almost certainly a bug.

**Why:** Confirmed as the root cause of the seinn LRU cache-thrash incident (2026-05-19, 2026-05-20). `evictIfOverBudget` in `lucos_media_seinn/src/service-worker/cache-eviction.js` was protected by `evictionLock`; `updateLRUTimestamp` (read-modify-write on the same LRU store) was not. Under parallel preloads, the unprotected function lost updates, gradually scrambling the LRU ordering until the cache started thrashing. Reported in `lucos_media_seinn#456`.

**How to apply:**
- When reviewing SW cache management, IndexedDB helpers, or any shared-state async operations: look for existing mutexes and check whether all related state-update paths are protected by them.
- Flag immediately if you see `forEach(async ...)` or `Promise.all(...)` over operations that share a mutable store.
- The pattern is subtle because the protected function (eviction) may look safe in isolation — the smell is the *contrast* between the two siblings.

**Also noted:** When investigating "music not playing" or other client-side player issues in code review, the browser console log is the highest-leverage artefact. Server logs may show webhook failures as a noisy side effect, not the root symptom.
