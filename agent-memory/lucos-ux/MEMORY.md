# Memory

## Feedback

- [Thin frontend over API](feedback_thin_frontend_principle.md) — lucos frontend-manager projects should be thin pass-throughs; push ordering/sorting to the API
- [FYI is not dispatch](feedback_fyi_not_dispatch.md) — only start work on an explicit "implement issue {url}" message; FYIs and triage notifications are read-only
- [Error copy: explicit retry guidance](copy_error_retry_guidance.md) — errors with known persistence must say "retry" or "don't retry"; prose in `<p>`, technical detail in `<pre>`

## Project

- [SW health pattern](project_sw_health_pattern.md) — SW-backed UIs (seinn) can degrade silently; pattern for surfacing SW health + guided recovery in UIs

## Reference

- [arachne MCP entity counts](reference_arachne_mcp_counts.md) — `list_types` inflates counts via OWL inference; use `find_entities` result count for precision
