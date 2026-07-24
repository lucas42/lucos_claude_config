---
name: review-android-mediastore-pitfalls
description: Never approve a MediaStore selection string using NOT IN (?, ?) with bound parameters — some Android versions silently return an empty cursor instead of erroring. Filter in Kotlin instead.
metadata:
  type: feedback
---

The correct approach is to apply the exclusion filter in Kotlin inside the cursor loop (e.g. `if (ownerPackage in EXCLUDED_PACKAGES) continue`), not in the ContentProvider selection string.

Confirmed as a real production regression in lucos_photos_android: the TikTok `OWNER_PACKAGE_NAME NOT IN (?, ?)` filter broke sync entirely from v1.0.13 on at least one device — no error, no exception, just zero results. Fixed in PR #79.
