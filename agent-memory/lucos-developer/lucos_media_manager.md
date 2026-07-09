---
name: lucos-media-manager
description: Java/Maven structure, tag write path, and test gotchas for lucos_media_manager
metadata:
  type: project
---

- **Language**: Java (requires Java 25 / Maven). Tests run in Docker: `docker run --rm -v $PWD:/app -w /app maven:3-eclipse-temurin-26-alpine mvn clean test`.
- **MediaApi**: `fetch()` (GET), `patch()` (PATCH with JSON body).
- **Tag write path**: `PATCH /v3/tracks/{trackid}` with body `{"tags": {"lastSuccessfulPlay": [{"name": "..."}]}}`. NOT `/v3/tracks/{trackid}/tags` (that returns 404).
- **Track.recordTag(tagName)**: best-effort — logs errors, never throws. Returns silently if `trackid` is null.
- **PlaylistTest**: use `new HashMap<>(Map.of(...))` not `Map.of()` for Track metadata — Track constructor calls `metadata.put()` which fails on immutable maps.
