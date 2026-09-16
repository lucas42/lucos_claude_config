---
name: loganne-wire-format-gotchas
description: Payload-shape traps in loganne's GET /events — timestamp key is `date`, feed is newest-first, events are not flat, and before-state fields do exist
metadata:
  type: reference
---

Four things about `GET https://loganne.l42.eu/events` that cost time if you assume otherwise. All observed directly in a production feed on 2026-09-16 (323 events spanning a week).

- **The timestamp key is `date`, not `dateTime`.** ISO 8601 with milliseconds and a `Z` suffix. Guessing `dateTime` yields `None` for every event, which looks exactly like a feed with no timestamps.
- **The feed is returned newest-first.** Sort explicitly before doing anything order-dependent; don't assume chronological.
- **Events are not flat.** `webhooks` is a nested object keyed by consumer, each holding `status` and an `attempts` list with per-attempt timestamps. Useful for debugging delivery, but it breaks any code assuming a flat record.
- **Before-state fields do exist**, contrary to the general claim in `references/monitoring-loganne.md`. `collectionSwitch` from `lucos_media_manager` carries `previousName` and `previousSlug` alongside `name` and `slug`. The doc's claim is true for the *track* case it cites (`storedTrack` published, `existingTrack` not) but is written as a general rule, and isn't one.

**The underlying lesson is the doc's own advice, which its general claims violate:** check an actual payload rather than reasoning from the producing service's internal signature — or from a summary of the wire format, including this one. Field sets vary by `type` and by producer.

Also present on every event: `level` (see [[loganne-event-level]]), `uuid`, `source`, `type`, `humanReadable`. Everything else is type-specific.
