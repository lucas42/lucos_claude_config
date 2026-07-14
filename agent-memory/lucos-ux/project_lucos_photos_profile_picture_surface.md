---
name: lucos_photos_profile_picture_surface
description: Where rarely-used per-item actions belong relative to a grid view — pin on the detail page, revert next to the visible problem (photos#473)
metadata:
  type: project
---

Design pattern settled on lucos_photos#473 (manual profile-picture pinning), worth reusing elsewhere in the estate: when an action is rare and would otherwise need a per-tile affordance smeared across every item in a grid (`/people/{id}`'s photo grid, in this case), look for a detail/single-item view that's already a natural decision point instead. `/photos/{id}` already lists tagged people; "Set as profile picture" hangs off that list rather than adding a pin-icon to every tile in `/people/{id}`.

**Why:** a hover-only per-tile icon fails for touch and keyboard users; an always-visible one is persistent clutter for something used occasionally. The single-item detail page is where the user has already made the decision ("this photo is better than the current pick") — that's the natural point of action, not a scan-and-click over a grid.

Companion principle: place the **undo** near where the **problem** is visible, not near where the original action happened. Reverting a manually-pinned profile picture is a button on `/people/{id}` next to the (possibly wrong) picture itself, not on the specific photo that was originally pinned — the user is far more likely to be looking at the former than to remember the latter.

**How to apply:** before adding a per-tile action to any lucos grid/gallery view, check whether a detail view for that item type already exists and is a better-scoped home for it. See [[lucos_photos_person_flag_pattern]] for the companion "plain column, not a table" schema pattern from the same design pass (photos#471/#473).
