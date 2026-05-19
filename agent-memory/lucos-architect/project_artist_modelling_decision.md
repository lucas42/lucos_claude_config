---
name: artist-modelling-decision
description: Artist lives in lucos_media_metadata_api as mo:MusicArtist (decided 2026-05-19); membership deferred to #247
metadata:
  type: project
---

**Decision (lucas42/lucos_media_metadata_api#246, 2026-05-19):** Track artists are modelled as `mo:MusicArtist` in `lucos_media_metadata_api`, alongside Album (`mo:Record`). URI scheme `{MEDIA_METADATA_MANAGER_ORIGIN}/artists/{id}`. Schema `(id, name UNIQUE)` plus optional `owl:sameAs` for federation with `contacts:Person` / `eolas:Person`. `mo:MusicArtist` covers individuals and groups uniformly — no Person-vs-Group decision at ingest.

**Why this and not eolas:** Argued for hours through Person-vs-Group split (rejected — type-decision-at-ingest, see #237 thread), then Artist as new eolas type (initially recommended), then Artist in media_api (winning option). The eolas case rested on member-relation curation tooling and growth-shape forecasting. lucas42 confirmed members were a soft constraint ("should be possible / in a meaningful way") not a load-bearing requirement. Once members were dropped, Artist looked structurally just like Album: stub + sameAs. Album symmetry held cleanly.

**Membership tracked separately:** lucas42/lucos_media_metadata_api#247 ("Model artist membership"). Door left open via option (a): add a `members[]` relation on media's Artist storing `eolas:Person` / `contacts:Person` URIs as foreign refs, reusing `api/reconcile.go` pattern. Status: Ideation per lucas42's instruction. No active work planned.

**Why:** Architecture for music-domain entity types in the estate. Album precedent + member-relation as soft constraint together push toward media_api rather than eolas.

**How to apply:** When advising on future music-domain modelling questions, the precedent is "Album-like stub in media_api unless the entity has heavy outbound edges into Person-shaped concepts". The Artist-in-eolas case I initially built is documented as a what-if for if members ever become load-bearing. Related: [[check_value_when_fix_complexity_grows]] (the trigger that made me walk back the over-engineered version), [[vague_aesthetic_hedging]] (a recurring failure mode this thread surfaced), [[question_the_option_list]] (#237 was the original sin).
