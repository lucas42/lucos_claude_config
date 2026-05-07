---
name: URL field of an event is not an API path on the receiver
description: Diagnostic pattern — webhook/event URLs are identifiers, not paths to call on the receiver's API. Stripping the host and reusing the path silently breaks across system boundaries.
type: feedback
---

# Pattern — "URL field of an event is not an API path on the receiver"

When a webhook event or any cross-system message carries a `url` field, that URL is **a canonical identifier**, not necessarily a path to call on the API of the system you're talking to. The URL's host and the API's host are usually different systems with different path conventions (versioning, prefixes, routing).

A receiver that needs to fetch the referenced resource from its API must:

1. **Extract the canonical ID** (or other stable identifier) from the URL.
2. **Reconstruct the API path** using the receiver's *own* path conventions.

Stripping the host and reusing the path verbatim is unsafe — even if it happens to work today, it's a coincidence. The two systems' URL spaces evolve independently. lucas42's lucos estate has plenty of pairs where the user-facing UI host and the API host expose different paths for the same logical resource (e.g. `media-metadata.l42.eu/tracks/22510` is a track concept URI, but the v3 API path is `/v3/tracks/22510` on `media-api.l42.eu`).

**Telltale symptom:** an HTTP error from the receiver's API (404, 410, 401, etc.) on the *first* call after a refactor that introduced URL-to-path derivation. Usually deterministic — fails for every event of that type.

**Confirmation step:** `curl` the constructed URL with a real auth token. If the response says "v1 deprecated" or "use /v2/..." or "version not supported", you've found it. If it says "not found", check whether the path on the *target* system uses a different prefix to the path on the *source* system.

**The architectural smell** that should make you suspicious in code review: any time you see `URI.create(externalUrl).getPath()` followed by passing the result to your own API client, ask "does my API really use the same path layout as the URL's source system?" If those are different systems, the answer is almost certainly no.

**Caught 2026-05-07** in lucas42/lucos_media_manager#249. PR #246 introduced `String trackPath = URI.create(event.url).getPath(); fetchTrack(trackPath)` where `event.url = https://media-metadata.l42.eu/tracks/22510`. The webhook handler asked the media-api for `/tracks/22510`, which had been deprecated in the March 2026 v3 migration — every other caller in the codebase used `/v3/tracks/...`. First trackUpdated event after deploy → 410 Gone → `webhook-error-rate` red.

## Sub-pattern — mocks that lock in the wrong contract

Often paired with the above failure mode: the unit test for the buggy code mocks the dependency with the *same* (wrong) call signature the production code uses. The mock matches the call, the test passes, the integration is never exercised. In #249, `WebhookControllerTest` had:

```java
when(mediaApi.fetchTrack("/tracks/1347")).thenReturn(updatedTrack);
verify(mediaApi).fetchTrack("/tracks/1347");
```

…which "validates" exactly the broken behavior. When proposing fixes for this class of bug, also ask: **does the test stub use the right path, or just the same path the production code uses?** Update both, or the next person to look at the test will assume the contract is correct.

The defence isn't "stop using mocks" — it's "don't mock what you don't understand". For cross-system contracts, prefer integration tests against a stubbed real-shape API (e.g. WireMock, MockServer) that fails when the path doesn't match the documented one. Or pull the path-construction into a small testable helper with its own unit tests against the documented API spec.
