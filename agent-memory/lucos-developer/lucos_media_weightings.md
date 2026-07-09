---
name: lucos-media-weightings
description: Test runner, tag format, and recency-logic notes for lucos_media_weightings
metadata:
  type: project
---

- **Tests**: `./run_tests.sh` (from repo root) — uses `pipenv run python3` for each file; bare `python3` misses the virtualenv. All test files in `src/`.
- **Tag format**: v3 tags are `{tagName: [{name: value}]}`. Use `getTagValue(tags, key)` to read.
- **Recency logic**: `lastSuccessfulPlay` tag → ÷50 if <1 day, ÷10 if <7 days. Bypassed if `about`/`mentions` matches `currentItems`. Follows same timezone-normalisation pattern as `added` tag.
- **loganne client**: v2 (`>=2.0.0`). `updateLoganne(type, humanReadable, level, ...)` — `level` is required; raises `ValueError` for unknown values before any HTTP call.
