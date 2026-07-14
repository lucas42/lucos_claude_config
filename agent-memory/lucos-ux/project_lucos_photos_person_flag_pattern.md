---
name: lucos_photos_person_flag_pattern
description: lucos_photos convention for standing user judgements on a Person (is_background, flagged_at) — plain nullable column + PUT/DELETE pair, not a table
metadata:
  type: project
---

lucos_photos (api/app/routers/people.py) has an established pattern for "the user has expressed a standing judgement about this group" state on `Person`: a plain nullable column, not a separate table — with a `PUT`/`DELETE /people/{person_id}/<thing>` endpoint pair that mirrors each other, a field surfaced in `person_to_dict`, and a matching pair of loganne events (`personMarkedBackground`/`personUnmarkedBackground`).

`is_background` is the precedent. `flagged_at` (added via lucos_photos#471, a nullable tz-aware `DateTime` rather than a boolean, so the badge gets both the predicate and the display date in one column) follows the same shape: `PUT`/`DELETE /people/{person_id}/flag`, `flaggedAt` in `person_to_dict`, `personFlagged`/`personUnflagged` loganne events.

**Why:** lucos_photos is single-user with a flat `photos:use` scope — no admin/review-queue distinction exists, so richer shapes (dedicated tables, reason enums) tend to be over-built relative to who actually reads the data. See [[feedback_pull_architect_on_schema_scope_changes]] for how this was discovered on #471.

**How to apply:** When a future lucos_photos feature needs a "user flagged/marked/ignored this" toggle on `Person` (or similar entities), default to a plain column + PUT/DELETE pair before reaching for a table. Only justify a separate table if there's a genuine multiplicity need (more than one outstanding instance per entity) or an actual consumer of per-instance detail beyond a single badge.

Also noted while reviewing #471: `Person.profile_photo_id` / `profile_auto_generated` already exist and the worker (`generate_profile_picture`) already respects a manual override — but no API endpoint sets `profile_auto_generated = False`, so the override is unreachable in production. Tracked as lucos_photos#473 (architect-raised). Relevant if a future "choose profile picture" UI request comes in — the backend groundwork is already half there.
