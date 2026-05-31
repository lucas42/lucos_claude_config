---
name: media-ecosystem-uri-namespace
description: Media ecosystem (lucos_media_*) stores only its own URIs or eolas URIs; never contacts URIs directly (ADR-0005)
metadata:
  type: reference
---

**Principle (`lucos` ADR-0005, Accepted; status-line flip in lucos#206 on 2026-05-31, decision settled since #163 closed):** The `lucos_media_*` services store only their own URIs or `lucos_eolas` URIs in persistent entity references. They never store `lucos_contacts` URIs directly. Eolas-side counterpart is `lucos_eolas` ADR-0001 (canonical-home contract, PR #288).

Contacts indirection happens via `preferredIdentifier` on the eolas side: an `eolas:Person` can carry a `preferredIdentifier` triple pointing at a `contacts:Person`, and `lucos_arachne` federates the inference so consumers see the canonical contact name surfaced from a media-stored eolas URI.

**Scope:** Media-ecosystem-specific. Other services (`lucos_photos` for face↔contact linking, `lucos_calendar` for calendar feeds) hold contacts URIs as appropriate. The principle does not generalise estate-wide.

**Enforcement:** lucas42/lucos_media_metadata_api#245 (tag-write URI validation) — allowlist for `RequiresURI` predicates is `eolas.l42.eu` only (plus the media service's own host where applicable).

**Pattern for personal contacts referenced from media:** Use the same lookup-or-create pattern as composer/producer (#237). If "Luke Blaney" appears in a tag, create or look up `eolas:Person/luke-blaney` (with the `preferredIdentifier` link to his contact set on the eolas side). Media stores the eolas URI.

**What this composes with:**
- `lucos_loganne#370` re-fetch-from-source convention — unaffected. Media services that hold eolas URIs continue to re-fetch from eolas on `itemUpdated`. They just never need to re-fetch from contacts because they never hold contacts URIs.
- Federation in arachne via `preferredIdentifier` — does the heavy lifting for cross-system entity inference.

**Knock-on tickets (all updated 2026-05-19):**
- #138 → #248 (remove `contactDeleted` handler, includes loganne deregistration)
- #139 → scope reduced to `itemUpdated` only
- #244 → developer to drop contacts half
- #245 → allowlist eolas-only
- #246 → Artist `owl:sameAs` constrained to `eolas:Person`
- #247 → Artist member URIs constrained to `eolas:Person`

**Origin of the principle:** lucas42's pushback on PR #244 in architect chat on 2026-05-19. My initial framing ("contacts is a source of pushes, not pulls") was wrong — it would have conflicted with loganne#370's settled re-fetch-from-source convention. lucas42's narrower framing (constrain what URIs the ecosystem stores, not how it re-fetches) avoids the conflict. Related: [[verify_path_before_defensive_code]] — the defensive code that motivated the original "pre-link window" framing was for a scenario no code path produces.
