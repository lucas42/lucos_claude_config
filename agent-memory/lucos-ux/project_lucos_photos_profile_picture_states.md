---
name: lucos_photos_profile_picture_states
description: Async-generated images have a broken-load state and a none state that collapse visually; a theoretical third "pending" state needs a genuinely new signal, not a cheap serializer field — verify write-order before assuming otherwise
metadata:
  type: project
---

lucos_photos#476 (filed 2026-07-19, following a site-reliability consultation prompted by a stalled-background-job incident on a person's profile picture): any place a lucos UI displays an image generated asynchronously by a background worker can have states that are easy to accidentally collapse together:

1. **None** — no source data exists to generate from, will never have an image.
2. **Broken** — a derivative exists but the `<img>` failed to load (404/network/stale reference). Without an `onerror` handler this falls through to the browser's default broken-image glyph, which reads as a rendering bug rather than "temporarily unavailable," and looks the same as "none" to a user either way.

A theoretical third state, **"pending"** (queued/chosen but not yet generated), is tempting to add but check the write order before assuming it's cheap. In lucos_photos, I first assumed `Person.profile_photo_id` gets set before the derivative file is written, which would have made "pending" trivially exposable (just surface the existing field). **That was wrong** — site-reliability caught it: the worker writes the derivative file first, then commits `profile_photo_id` (`shared/lucos_photos_common/jobs.py`, save then DB update a few lines later), confirmed empirically too (778/778 people with `profile_photo_id` set have the file; zero mismatches). Consequence: `profile_photo_id` is NULL in *both* "pending" and "none" — they are genuinely indistinguishable in the current data model, and building the distinction needs a real new signal (job-queue introspection, or deriving "has unprocessed input"), not a small serializer change. Given that real cost, and that the failure mode is self-correcting/internal-only, it may not earn its keep at all — weigh it as an open question, don't default to building it.

**Lesson: never assert a DB-write-vs-derivative-write ordering from memory or assumption — read the actual worker code (or ask the SRE who has DB access) before it becomes a load-bearing premise in a design recommendation.** I filed a public issue with the wrong ordering as fact before verifying it, and had to publicly correct it after site-reliability checked. [[feedback_verify_sandbox_currency]] covers the adjacent "checkout is stale" version of this; this is the "code was read but the fact still wasn't verified/traced carefully enough" version — reading a file isn't the same as tracing execution order through it.

**Pattern to reuse for the parts that DID hold up:**
- Don't use an animated spinner for a genuinely-long wait (lucos_photos' own `index.html` spinner is fine for a video encode, wrong for a worker batch that runs hourly) — animated "in progress" cues mislead at long timescales and add unneeded motion for vestibular-sensitive users. Static icon + text label instead, if a pending state is built at all.
- Reuse an existing `onerror`-swap-to-placeholder precedent if the codebase already has one (lucos_photos' `index.html` had one for thumbnails) rather than inventing a new failure-handling idiom.
- Don't default to initials-based placeholders for anonymous/unnamed entities — check whether the domain actually has names to fall back on first. lucos_photos people frequently have no `display_name` at all, so initials would often be blank too.

**How to apply:** when reviewing or building any UI surface backed by an async-generated file (thumbnails, previews, derived images, rendered exports), don't assume "not yet generated" is a cheap addition — trace the actual write order in the worker code first. See [[lucos_photos_profile_picture_surface]] for the companion action-placement pattern from the same person-page area.
