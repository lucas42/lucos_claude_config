---
name: lucos-search-emits-eolas-uri-not-contacts
description: lucos-search widget (arachne-backed) emits the eolas person canonical URI as option value even in contact mode; contacts URI is owl:sameAs only — consumers must reverse-map
metadata:
  type: reference
---

The shared `lucos_search_component` web component (`<span is="lucos-search" ...>`, npm `lucos_search_component`, served as `/lucos_search_component.js`) sets each result option's `value` to the entity's **canonical knowledge-graph URI** = the **eolas** person URI `https://eolas.l42.eu/metadata/person/{N}/`, NOT a contacts URI.

- `data-is-contact="true"` only adds a Typesense filter `is_contact:=true` (narrows results to contact-linked people). It does NOT change the emitted URI.
- In arachne the contacts URI is stored as `owl:sameAs` on the eolas Person entity (e.g. `eolas.l42.eu/metadata/person/2/` → `owl:sameAs https://contacts.l42.eu/people/2`), so a consumer wanting a **contact id** must resolve via `owl:sameAs`, not by string-munging the eolas path. The numeric ids may coincide (2==2 for Luke) but that's not guaranteed across the id-spaces.

**Bit lucos_photos 2026-07-02:** `person.html` `handleContactChange()` parsed the option value with `/\/people\/(\w+)\/?$/` (a contacts.l42.eu shape, written 2026-03-13); after commit de91fb4 wired the contact picker to `lucos-search` with `data-is-contact="true"`, new picks emitted the eolas URI → regex failed → `Could not extract contact ID from URI` → contact linking via search silently broke. Already-linked case worked only because the pre-selected `<option>` is hardcoded to `contacts.l42.eu/people/{contactId}` in the template. Diagnosed for team-lead; awaiting issue dispatch to lucos-developer. Any other consumer of `lucos-search` in contact mode is at the same risk — the widget contract hands out eolas URIs. See [[pattern_stale_sandbox_checkouts]] for the verify-against-origin/main discipline used here.
