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
- **The error REASON is NOT in the Loganne event.** `lastErrorMessage` is marked `LoganneSilent` in `lucos_media_metadata_api/predicateconfig/registry.go:180-183` — it's stored on the track but deliberately stripped from the emitted event. The event carries only `track.{fingerprint,duration,url,id,tags,weighting,collections}` + humanReadable "Track X errored". So Loganne alone tells you THAT tracks errored, never WHY (decode vs fetch). Verified 2026-06-05.
- The reason lives in **media_manager (ceol) container stdout**: `Playlist.java:75` logs `NOTICE: Track <uuid> flagged with error: <errorMessage>`. That's the only server-side place the decode-vs-fetch breakdown survives — and it's **ephemeral** (in-memory container log, lost on the next ceol redeploy, which is frequent). Race the rotation.
- Client log shows hundreds of `Skipping track Unable to decode audio data` lines and ` Uncaught (in promise)` paired 1:1 with sporadic `/v3/playlist/null/{uuid}/current-time` 400s.
- Knock-on: brief `lucos_loganne` `event-loop-lag-low` flaps from outbound webhook volume (~25 trackUpdated/min × 3 webhooks each).

## Don't be fooled

- The `playlist=null` slug in URLs is a known intentional placeholder (#437 closed `not_planned`) — manager ignores it. Not the cause.
- The `/_info` `media-manager` and `empty-queue` checks both stay green throughout — the manager is functioning correctly; only the *device* is broken.
- The cache-thrash-banner mechanism exists but watches the wrong thing for this — don't assume "banner didn't fire ⇒ no thrash."

## The fix — SHIPPED

The playback-error thrash detector shipped via lucas42/lucos_media_seinn#482 / PR #483 (merged 2026-05-26), using the abstracted `makeSlidingWindowDetector` from `cache-eviction.js` to watch `playTrack` catch frequency. **Confirmed working 2026-06-05**: the banner fired and bounded the burst (visible as multiple `?token=` player reloads in the router log). The "banner-not-firing gap" is CLOSED — do not cite it as open.

## Verifying a recurrence is this and not something else

When suspecting a seinn playback-thrash recurrence, stitch three sources (no single log has the whole story):

1. **Loganne events** for the window: count `humanReadable | test("errored")`. Confirms the burst, the trigger (look for the preceding `deviceSwitch`/`collectionSwitch`), blast radius (distinct `track.id` count — ≈ whole collection ⇒ systemic), and that webhooks held (`webhooks.status: success`). Does NOT give the reason.
2. **Router access log** on the host serving the audio (private.l42.eu = `lucos_router` on **xwing**): grep `private.l42.eu` + `/medlib/` in the window. **All 200 with full multi-MB GET bodies ⇒ server delivery is clean, failure is client-side** (decode). 4xx/5xx ⇒ a real fetch/auth/missing-file problem. (Audio does NOT traverse avalon's router.)
3. **media_manager stdout** (`lucos_media_manager` on **avalon**): `docker logs lucos_media_manager 2>&1 | grep -a "flagged with error" | sed -E 's/.*flagged with error: //' | sort | uniq -c` → the decode-vs-fetch split. Use `-a` (Irish track names break grep's UTF-8 detection).
4. If `webhook-error-rate` is red instead, it's the older eviction-side pattern (#469/#470/#473 mechanism).

2026-06-05 worked example: trigger = switch to device "Galactica" + collection "All Music" at 09:26Z on Chrome 148/macOS; ~260 distinct tracks errored (whole collection); 598/598 medlib fetches 200 w/ full bodies; manager stdout = 235 "Unable to decode audio data" + 35 "Failed to fetch" ⇒ client-side decode failure on that device, server fully exonerated. The 35 fetch errors are the `buffers.js:27-31` rejected-promise-cache artefact, not real network failures.
