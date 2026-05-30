---
name: lucos-media-metadata-api-eolas-ssrf-pattern
description: SSRF guard for eolas-fetch paths in lucos_media_metadata_api is fetchEntityNameFromSource (hostname whitelist), NOT ValidateURIOrigin — important for future go/request-forgery false-positive assessments
metadata:
  type: reference
---

## SSRF Protection on Eolas-Fetch Paths (lucos_media_metadata_api)

**Key finding from PR #284 review (2026-05-30):** The `go/request-forgery` CodeQL alert on `fetchEolasName` in `api/eolas.go` is a false positive. Alert #2 dismissed by lucos-security[bot].

### The actual guard: `fetchEntityNameFromSource`

`fetchEntityNameFromSource` (in `api/webhooks.go`) is the production implementation of `entityNameFetcher`. It validates two conditions before routing to `fetchEolasName`:
1. Scheme must be `https`
2. Hostname must be exactly `eolas.l42.eu`

Any URI with a different host returns an error without making a network request.

### What `ValidateURIOrigin` does NOT cover

`ValidateURIOrigin` (in `predicateconfig/predicateconfig.go`) is only called on the **tag write paths** (`updateTagsV3`, `updateTagsV3IfMissing`) for predicates with `RequiresURI() = true` (i.e. `ValueShapeURIObject`). The predicates that call `fetchEolasName` via `ResolveURIToName` are `composer` and `producer` — both have `ValueShapeURIObject`, so `ValidateURIOrigin` IS called before `fetchEolasName` on these paths (double protection).

The **webhook paths** (`itemUpdated`, `contactLinked`, `itemMerged` in `WebhooksController`) call `entityNameFetcher` directly, **bypassing `ValidateURIOrigin` entirely**. Only `fetchEntityNameFromSource`'s hostname whitelist applies here.

### Additional defence: webhook auth

`/webhooks` is inside `NewAuthenticatedServer`, so Bearer token auth is required. Unauthenticated callers cannot send crafted payloads.

### For future CodeQL go/request-forgery alerts on this codebase

The correct dismissal reasoning: "`fetchEntityNameFromSource` enforces scheme=https and hostname=eolas.l42.eu on every path to `fetchEolasName`. SSRF to arbitrary hosts is impossible. (`ValidateURIOrigin` is not the guard here — the hostname whitelist in fetchEntityNameFromSource is.)"

Do NOT cite `ValidateURIOrigin` as the guard — it is not called on webhook paths. A reviewer citing only `ValidateURIOrigin` has the right conclusion but wrong reasoning.
