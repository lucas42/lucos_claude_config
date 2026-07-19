---
name: lucos_photos_profile_picture_states
description: Three backend states (none/pending/broken) for async-generated images collapse to two indistinguishable UI states — pattern applies to any lucos UI with a worker-generated derivative
metadata:
  type: project
---

lucos_photos#476 (filed 2026-07-19, following a site-reliability consultation prompted by a stalled-background-job incident on a person's profile picture): any place a lucos UI displays an image generated asynchronously by a background worker has (at least) three distinct states that are easy to accidentally collapse into two:

1. **None** — no source data exists to generate from, will never have an image.
2. **Pending** — the system has decided an image will exist (e.g. `Person.profile_photo_id` is set) but the derivative file hasn't been produced yet. In lucos_photos, `person_profile_picture_url()` (`api/app/serializers.py`) only checks derivative-file existence, so it can't tell "pending" from "none" — both serialize as `null`. **The API/serializer has to expose the distinction explicitly; it's not free from the existing data.**
3. **Broken** — a derivative exists but the `<img>` failed to load (404/network/stale reference). Without an `onerror` handler this falls through to the browser's default broken-image glyph, which reads as a rendering bug rather than "temporarily unavailable."

**Why this matters:** users can't tell "permanently empty" from "check back later" from "something's actually wrong" unless all three are visually and semantically distinct. Screen reader users get nothing at all if the placeholder is a bare unlabelled `<div>` and the failed `<img>` has `alt=""`.

**Pattern to reuse:**
- Don't use an animated spinner for "pending" unless the wait is genuinely short (lucos_photos' own `index.html` spinner is fine for a video encode, wrong for a worker batch that runs hourly) — animated "in progress" cues mislead at long timescales and add unneeded motion for vestibular-sensitive users. Static icon + text label instead.
- Reuse an existing `onerror`-swap-to-placeholder precedent if the codebase already has one (lucos_photos' `index.html` had one for thumbnails) rather than inventing a new failure-handling idiom.
- Don't default to initials-based placeholders for anonymous/unnamed entities — check whether the domain actually has names to fall back on first. lucos_photos people frequently have no `display_name` at all, so initials would often be blank too.

**How to apply:** when reviewing or building any UI surface backed by an async-generated file (thumbnails, previews, derived images, rendered exports), check whether "not yet generated" and "will never exist" share a code path before assuming a single empty/placeholder state is sufficient. See [[lucos_photos_profile_picture_surface]] for the companion action-placement pattern from the same person-page area.
