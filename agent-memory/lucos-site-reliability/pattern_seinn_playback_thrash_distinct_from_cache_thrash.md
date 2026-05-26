---
name: pattern-seinn-playback-thrash-distinct-from-cache-thrash
description: seinn playback-side thrash (decode/fetch failures) is a DIFFERENT failure mode from the eviction-thrash that #460/#473 detect — the banner never fires for it
metadata:
  type: pattern
---

# seinn playback-error thrash ≠ cache-eviction thrash

The existing `cache-thrash-banner` (lucas42/lucos_media_seinn#460, detection in #473) only fires from `src/service-worker/cache-eviction.js` on two signals:

1. **≥20 successful CacheStorage evictions in 60 s** (`thrashDetector`)
2. **≥2 eviction failures in 60 s** (`failureDetector`)

Both signals are about *cache churn*. They are silent for the **playback-side thrash** failure mode:

- `audioContext.decodeAudioData(arrayBuffer)` rejects with **"Unable to decode audio data"** — bytes already in cache are undecodable. No eviction happens; SW sees nothing wrong.
- `fetch(url)` itself rejects with **"Failed to fetch"** — request never reaches the cache layer.

In both cases the client `web-player.js::playTrack` catch block fires `?action=error` → `lucos_media_manager.flagTrackAsError` → playlist advances → next track also fails → 2.4-second loop. No webhook failures (manager copes); no monitoring alert (`/_info` doesn't model per-device error rate); only ambient silence tells the user something is wrong. Recovery is **manual tab reload only** because `src/client/buffers.js:27-31` caches rejected promises indefinitely.

## Diagnostic signatures

- 100s of `trackUpdated` "errored" events from `lucos_media_metadata_api` in a Loganne window, all with webhook `status: success` (so webhook-error-rate stays green).
- Mix of `lastErrorMessage` values: `"Unable to decode audio data"` and `"Failed to fetch"`, often interleaved/back-to-back-phased.
- Client log shows hundreds of `Skipping track Unable to decode audio data` lines and ` Uncaught (in promise)` paired 1:1 with sporadic `/v3/playlist/null/{uuid}/current-time` 400s.
- Knock-on: brief `lucos_loganne` `event-loop-lag-low` flaps from outbound webhook volume (~25 trackUpdated/min × 3 webhooks each).

## Don't be fooled

- The `playlist=null` slug in URLs is a known intentional placeholder (#437 closed `not_planned`) — manager ignores it. Not the cause.
- The `/_info` `media-manager` and `empty-queue` checks both stay green throughout — the manager is functioning correctly; only the *device* is broken.
- The cache-thrash-banner mechanism exists but watches the wrong thing for this — don't assume "banner didn't fire ⇒ no thrash."

## The fix

Use the already-abstracted `makeSlidingWindowDetector` from `cache-eviction.js` to add a third detector watching `playTrack` catch frequency. Same banner copy works (it already says "Music isn't playing — reload to fix it" and reloads with SW unregister). Tracked in [[reference-seinn-issue-482]] — lucas42/lucos_media_seinn#482, filed 2026-05-26.

## Verifying a recurrence is this and not something else

When suspecting a seinn playback-thrash recurrence:

1. Pull Loganne events for the window, count `humanReadable | test("errored")`. Group by `track.tags.lastErrorMessage[0].name`.
2. If you see `Unable to decode audio data` and/or `Failed to fetch` in the hundreds with all webhook deliveries succeeding, it's this pattern.
3. If you see `webhook-error-rate` red instead, it's the older eviction-side pattern (#469/#470/#473 mechanism).
4. If the user's symptom was "I had to manually refresh", the banner-not-firing gap is still present (until #482 ships).
