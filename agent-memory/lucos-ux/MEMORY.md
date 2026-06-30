# Memory

## Feedback

- [Verify sandbox currency before filing bugs](feedback_verify_sandbox_currency.md) — run `git -C ~/sandboxes/{repo} log HEAD..origin/main --oneline` before asserting cross-repo code has a problem; stale snapshots caused 4 false positives in aithne review (2026-06-30)
- [Thin frontend over API](feedback_thin_frontend_principle.md) — lucos frontend-manager projects should be thin pass-throughs; push ordering/sorting to the API
- [FYI is not dispatch](feedback_fyi_not_dispatch.md) — only start work on an explicit "implement issue {url}" message; FYIs and triage notifications are read-only
- [Error copy: explicit retry guidance](copy_error_retry_guidance.md) — errors with known persistence must say "retry" or "don't retry"; prose in `<p>`, technical detail in `<pre>`
- [Edit tool smart quotes in JS](feedback_edit_tool_smart_quotes.md) — Edit tool can introduce U+2018/U+2019 as JS delimiters; use Python byte-level writes for JS string literals with apostrophes
- [Always use create-pr for any PR](feedback_use_create_pr_always.md) — use `create-pr` (not raw `gh-as-agent ... pulls`) for all PRs, including ad-hoc proactive fixes; it handles supervised-repo lucas42 reviewer request automatically
- [Contrast ratio verification](feedback_contrast_ratio_verification.md) — never assert a specific contrast ratio in a PR test plan from hand calculation; verify with WebAIM first (hand calc gave 3.05:1 for #c49000, correct is 2.86:1 — caused CHANGES_REQUESTED)

## Project

- [SW health pattern](project_sw_health_pattern.md) — SW-backed UIs (seinn) can degrade silently; pattern for surfacing SW health + guided recovery in UIs
- [CSP data: URI img-src](project_csp_data_uri_img_src.md) — CSS background-image data: URIs need `img-src data:` explicitly; style-src alone isn't enough

## Reference

- [arachne MCP entity counts](reference_arachne_mcp_counts.md) — `list_types` inflates counts via OWL inference; use `find_entities` result count for precision
