---
name: feedback-ssrf-request-forgery-assessment
description: Correct guard to cite when assessing go/request-forgery CodeQL alerts involving fetchEolasName in lucos_media_metadata_api
metadata:
  type: feedback
---

When assessing a CodeQL `go/request-forgery` (or SSRF-class) alert on `fetchEolasName` in lucos_media_metadata_api, cite **`fetchEntityNameFromSource` hostname whitelist** as the universal guard — NOT `ValidateURIOrigin`.

**Why:** `ValidateURIOrigin` is only on the save path (`updateTagsV3` / `updateTagsV3IfMissing`). The webhook paths (`itemUpdated`, `contactLinked`, `itemMerged` in `webhooks.go`) call `entityNameFetcher` → `fetchEntityNameFromSource` → `fetchEolasName` directly, bypassing `ValidateURIOrigin` entirely. Citing it as covering "every code path" is wrong.

The actual universal guards that make SSRF impossible:
1. `fetchEntityNameFromSource` enforces `scheme=https` and `hostname == eolas.l42.eu` before routing to `fetchEolasName`.
2. `/webhooks` endpoint is behind Bearer auth, so the webhook path is not open to arbitrary callers.

**How to apply:** In any future SSRF false-positive write-up involving `fetchEolasName`, lead with the `fetchEntityNameFromSource` hostname check. Mention `ValidateURIOrigin` only if explaining the save-path defence specifically. Confirmed via lucos-security review of PR #284 (2026-05-30).
