---
name: review-datetime-tz-normalisation
description: never blindly append +00:00 to a non-Z timestamp — parse first, then check tzinfo is None
metadata:
  type: feedback
---

Timestamps that don't end in `Z` may already carry an explicit offset (e.g. `+05:30`). Blindly appending `+00:00` to "normalise" them produces a malformed string.

**Correct pattern:**
```python
s = s.replace("Z", "+00:00")
dt = datetime.fromisoformat(s)
if dt.tzinfo is None:
    dt = dt.replace(tzinfo=timezone.utc)
```
Parse first, then only assume UTC if `tzinfo` actually comes back `None`.

**Why:** missed this in lucos_media_weightings PR #192 v1 — lucas42 caught it. Apply this check any time a PR touches timestamp-parsing/normalisation code, especially code that ingests timestamps from external or third-party sources where the offset format isn't guaranteed.
