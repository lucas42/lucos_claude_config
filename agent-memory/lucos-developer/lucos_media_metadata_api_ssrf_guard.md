---
name: lucos-media-metadata-api-ssrf-guard
description: CodeQL #284 false-positive — real SSRF guard in lucos_media_metadata_api is fetchEntityNameFromSource's whitelist, NOT ValidateURIOrigin
metadata:
  type: reference
---

## lucos_media_metadata_api — SSRF guard location (CodeQL #284 false-positive)

CodeQL #284 flagged an SSRF risk in lucos_media_metadata_api. The real SSRF guard is **`fetchEntityNameFromSource`'s scheme+hostname whitelist** — it validates that the URI scheme is `https` and the hostname is in an explicit allowlist before making any outbound request.

`ValidateURIOrigin` is a *different* function that does origin validation for inbound requests (checking caller identity), NOT outbound SSRF prevention. The CodeQL alert incorrectly assumed `ValidateURIOrigin` was the guard; it is not.

**Why it matters:** If future CodeQL alerts flag SSRF on paths that flow through `fetchEntityNameFromSource`, verify the whitelist is in place before treating it as a real finding. Don't assume `ValidateURIOrigin` provides SSRF protection — it doesn't.
