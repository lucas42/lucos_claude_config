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
- **The error REASON *is* in the Loganne event** — nested at `track.tags.lastErrorMessage` (a list of `{name}`), present on every errored event (verified 274/274 on 2026-06-05). Group by it to get the decode-vs-fetch split straight from the central feed, **no SSH required**. CAUTION (the trap I fell into 2026-06-05): a naïve dump of the event's top-level / `track` keys shows only `tags` as a key and the ~1.5 KB `fingerprint` will blow your JSON-truncation budget before `track.tags` prints — expand `track.tags` explicitly.
- `lastErrorMessage` is marked `LoganneSilent` in `registry.go:183` — this does NOT strip it from the payload. It only means the tag is ignored during humanReadable *message selection* (so a PATCH carrying both `lastError` + `lastErrorMessage` still emits the bespoke "Track X errored" line instead of generic "updated"). The value still ships in `track.tags`.
- Corroborating source (rarely needed): media_manager (ceol) stdout logs `NOTICE: Track <uuid> flagged with error: <msg>` (`Playlist.java:75`). Use `grep -a` (Irish track names break UTF-8 detection). Ephemeral — lost on ceol redeploy — so prefer Loganne.
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

1. **Loganne events** for the window (the one source that has everything — start and usually finish here): count `humanReadable | test("errored")`; group by `track.tags.lastErrorMessage[0].name` for the decode-vs-fetch split; read the trigger from the preceding `deviceSwitch`/`collectionSwitch`; blast radius from distinct `track.id` (≈ whole collection ⇒ systemic); webhook health from `webhooks.status`.
2. **Router access log** (private.l42.eu = `lucos_router` on **xwing**) — only if you need to confirm server delivery: grep `private.l42.eu` + `/medlib/` in the window. **All 200 with full multi-MB GET bodies ⇒ server clean, failure is client-side** (corroborates a "decode" reason). 4xx/5xx ⇒ a real fetch/auth/missing-file problem worth chasing. (Audio does NOT traverse avalon's router.)
3. If `webhook-error-rate` is red instead, it's the older eviction-side pattern (#469/#470/#473 mechanism).

2026-06-05 worked example: trigger = switch to device "Galactica" + collection "All Music" at 09:26Z on Chrome 148/macOS; ~260 distinct tracks errored (whole collection); Loganne `track.tags.lastErrorMessage` split = 238 "Unable to decode audio data" + 36 "Failed to fetch" (manager stdout agreed: 235/35); 598/598 medlib fetches 200 w/ full bodies ⇒ client-side decode failure on that device, server fully exonerated. The ~36 fetch errors are the `buffers.js:27-31` rejected-promise-cache artefact, not real network failures. Banner (#482/#483) fired and bounded it. Conclusion: observability here is GOOD — Loganne alone root-causes it.
