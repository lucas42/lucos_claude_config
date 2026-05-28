---
name: feedback-migration-slug-vs-name
description: Migration scripts that look up eolas entities must use a slug→name mapping when DB stores slugs but eolas stores display names
metadata:
  type: feedback
---

When writing a migration script that maps existing DB tag values to eolas entity URIs, the DB value and the eolas entity name are often **different formats**:

- DB stores slugs (e.g. `"domestic-abuse"`, `"self-harm"`)
- eolas entities are created with display names (e.g. `"Domestic Abuse"`, `"Self Harm (including suicide)"`)

**Never** build an eolas `byName` lookup map and then look up slug values directly — `"domestic-abuse"` ≠ `"domestic abuse"`, so every known entity would fall through to a create call and produce duplicates.

**Why:** Caught by lucas42 in PR #268. The migrate_offence_tags script initially used `strings.ToLower(slug)` to look up in a map keyed by `strings.ToLower(eolasName)`. They never matched.

**How to apply:** Always embed a `slugToName` mapping table in the migration script, sourced from the same formfields.php / controlled vocab that was used to populate eolas. The script then translates slug → canonical name → eolas entity lookup. Unknown slugs (not in table) should warn loudly and fall back to creating a new entity.

See: `lucos_media_metadata_api/scripts/migrate_offence_tags/main.go` (the `slugToName` map and `resolveSlug` function) as the reference pattern for future slug-based migrations.
