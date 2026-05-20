---
name: seinn-async-foreach-parallelism
description: forEach(async ...) is implicit parallelism — shared state mutations inside it need serialisation
metadata:
  type: feedback
---

`array.forEach(async fn)` fires all iterations concurrently without waiting. Any function called inside it that does a read-then-write on shared state (e.g. a cache LRU timestamp, a counter) is a race condition even if it looks sequential.

**Why:** Incident 2026-05-19-seinn-cache-thrash — `updateLRUTimestamp` had an unserialised read-modify-write inside a `tracks.forEach(async ...)` loop, while the sibling `evictIfOverBudget` was already mutex-protected. The resulting cache thrash caused music outages.

**How to apply:** When implementing any async loop that touches shared mutable state, use `for...of` with `await` for true serialisation, or chain onto an existing mutex/lock if one already guards the same state. In lucos_media_seinn specifically: `evictIfOverBudget` uses `evictionLock` — chain `updateLRUTimestamp` onto the same lock (one combined critical section) rather than introducing a second mutex.
