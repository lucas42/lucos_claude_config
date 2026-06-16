---
name: misleading-502-decode-not-unreachable
description: A proxy handler's "502 could not reach X service" can actually be a JSON decode failure of a 200 upstream — test the upstream call directly before blaming network/routing
metadata:
  type: project
---

A "502 Bad Gateway — could not reach <service>" from a thin proxy handler does **not** prove the upstream is unreachable. Handlers that map *any* error from their client call to a single 502 string will report a **decode/parse failure of a successfully-reached (HTTP 200) upstream** as "could not reach".

**Why:** First hit lucos_aithne#121 (2026-06-16). `GET /admin/contacts` 502'd on every request; admin forced to numeric-ID entry. The contacts API `GET /people/all` returned HTTP 200 fine, but aithne's `contactListItem.ID` was typed Go `string` while the API returns `id` as a JSON **number** (`"id": 788`) → `json: cannot unmarshal number into Go struct field ...id of type string` → `List()` errored → handler's catch-all mapped it to the misleading "could not reach" 502. The single-contact `Get()` path decoded into `map[string]any` (reads only `name`) so it was immune — which is why numeric-ID entry kept working. CI missed it because the test mock used `"id":"1"` (string), diverging from the real number shape.

**How to apply:**
1. On any "could not reach X" 502 from our own proxy/aggregator handlers, **test the upstream call directly first** (`curl` it from the host with the prod key) before reasoning about network/routing/firewall. A clean 200 upstream means the bug is in *our* parse/decode, not the gateway.
2. Suspect **mock/prod JSON type divergence** (string vs number, esp. ids) in Go structs — the unit test mock can hardcode a shape the real API never emits. The fix that *catches* it is correcting the mock to the real shape, not just the struct type.
3. The same `/admin/contacts` handler underpins the #120 agent grants-UI work — watch for it there too.
Related: [[pattern_scratch_image_no_ca_bundle]] (aithne scratch Go image, no shell — can't `docker exec sh`; get env via `docker inspect`, test calls from the host).
