---
name: reference-service-worker-ui-as-system-component
description: SW-backed UIs degrade over hours/days; treat the long-lived browser session as a system component with its own failure modes
metadata:
  type: reference
---

# Long-lived browser sessions are a system component

Apply when reviewing or designing any service-worker-backed lucos UI.

## The principle

A browser tab running for many hours is **not just a client** — it is a long-lived runtime hosting its own state machine (the service worker, its IndexedDB / CacheStorage stores, any in-memory bookkeeping). That state machine has degradation modes that:

- Don't show up in short-test sessions
- Aren't visible from the server side
- Don't recover via the usual "redeploy / restart container" mechanism — the only "restart" is the user reloading the tab, which they will only do if they realise something is wrong

When reviewing a feature that adds or extends a service worker (caching, offline support, background sync, push notifications), ask:

1. **What state does this SW accumulate over a long session?** Caches, timestamps, queues, bookkeeping maps — anything that grows or mutates over time.
2. **Is the long-running state mutation point-protected against concurrency?** Multiple concurrent fetches / preloads / event handlers are normal in SW code. Read-modify-write of any shared store needs explicit serialisation (mutex, locked critical section). Don't assume "it's all single-threaded JavaScript" — async interleaving is the failure mode.
3. **What is the SW's degradation signal?** If state drifts into a bad shape over hours, can the page tell? Can the server tell? If neither, the user discovers it by noticing the symptom (audio stops, save doesn't happen, etc.) — which is a slow, embarrassing detection path.
4. **What is the recovery path?** Tab reload is the brute-force answer. Are there lighter-weight escape hatches (re-init the SW, clear specific caches, switch to a fallback path)?

## Worked example

`lucos_media_seinn` (incident 2026-05-19 / 2026-05-20): `updateLRUTimestamp` in `cache-eviction.js` was a read-modify-write without a mutex, while the sibling `evictIfOverBudget` was already mutex-protected (`evictionLock`). Over hours of parallel preloads, the LRU store gradually lost fidelity until eviction targeted the actively-playing track. Silent to the page; visible only as "music stops".

The right protection pattern existed in the same file; it just wasn't generalised across both write sites. Convention-application gap.

## When to cite this

- New SW-backed feature PR or design.
- Any proposal that adds a long-lived browser-side cache / queue / state store.
- When asked to estimate "how reliable is this UI under multi-hour use?"

## See also

`docs/incidents/2026-05-19-seinn-cache-thrash-music-outages.md` in `lucas42/lucos`.
