---
name: pattern-aithne-contactid-string-vs-int-divergence
description: aithne represents the SAME contact id as a JSON string in the principal world (ExternalID) but an int in contactListItem — cross-referencing them in JS without String() coercion silently fails
metadata:
  type: project
---

In lucos_aithne the same lucos_contacts contact identifier has **two JSON types** depending on which endpoint emits it:

- `/admin/contacts` → `contactListItem{ ID int }` (enrolment.go:114) → `"id": 788` (**number**)
- `/admin/human-principals` (+ any principal endpoint) → `ContactID`/`ExternalID` is a Go **string** (store/store.go:60) → `"contact_id": "788"` (**string**)

**Why:** principals store the contact id as `ExternalID string` (it doubles as personas-slug for agents); the contacts proxy mirrors lucos_contacts' numeric `id` as an int. No single canonical type.

**How to apply:** any browser JS (or Go) that cross-references a contact id pulled from BOTH worlds must coerce — `String(c.id)` / `String(p.contact_id)`. A `Set` built from one and `.has()` queried with the other is strict-identity → silently matches nothing → empty result, green CI.

**Proven failures:**
- 2026-06-26 grants picker regression (PR #222 / aithne#219): datalist filter `principalContactIds.has(c.id)` (Set of string contact_ids vs int c.id) emptied the picker → name lookup dead, numeric-ID-only survived (P2, degraded). Fix = String() both sides in `templates/admin_grants.html`. Owner lucos-developer.
- Same string-vs-number class as [[pattern_misleading_502_decode_not_unreachable]] (aithne#121, contactListItem decode).

**Test gap that let it through:** PR #222's tests all asserted the *endpoint* JSON, none asserted the *picker resolves a name → id*. A pure type-mismatch between two green endpoints needs an integration assertion to catch.
