# Memory

## Feedback

- [Thin frontend over API](feedback_thin_frontend_principle.md) — lucos frontend-manager projects should be thin pass-throughs; push ordering/sorting to the API
- [FYI is not dispatch](feedback_fyi_not_dispatch.md) — only start work on an explicit "implement issue {url}" message; FYIs and triage notifications are read-only
- [Error copy: explicit retry guidance](copy_error_retry_guidance.md) — errors with known persistence must say "retry" or "don't retry"; prose in `<p>`, technical detail in `<pre>`
- [Edit tool smart quotes in JS](feedback_edit_tool_smart_quotes.md) — Edit tool can introduce U+2018/U+2019 as JS delimiters; use Python byte-level writes for JS string literals with apostrophes

## Project

- [SW health pattern](project_sw_health_pattern.md) — SW-backed UIs (seinn) can degrade silently; pattern for surfacing SW health + guided recovery in UIs
- [CSP data: URI img-src](project_csp_data_uri_img_src.md) — CSS background-image data: URIs need `img-src data:` explicitly; style-src alone isn't enough

## Reference

- [arachne MCP entity counts](reference_arachne_mcp_counts.md) — `list_types` inflates counts via OWL inference; use `find_entities` result count for precision
