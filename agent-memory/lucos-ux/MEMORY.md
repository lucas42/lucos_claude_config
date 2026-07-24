# Memory

## Feedback

- [Verify sandbox currency before filing bugs](feedback_verify_sandbox_currency.md) — run `git -C ~/sandboxes/{repo} log HEAD..origin/main --oneline` before asserting cross-repo code has a problem; stale snapshots caused 4 false positives in aithne review (2026-06-30)
- [Thin frontend over API](feedback_thin_frontend_principle.md) — lucos frontend-manager projects should be thin pass-throughs; push ordering/sorting to the API
- [FYI is not dispatch](feedback_fyi_not_dispatch.md) — only start work on an explicit "implement issue {url}" message; FYIs and triage notifications are read-only
- [Error copy: explicit retry guidance](copy_error_retry_guidance.md) — errors with known persistence must say "retry" or "don't retry"; prose in `<p>`, technical detail in `<pre>`
- [Edit tool smart quotes in JS](feedback_edit_tool_smart_quotes.md) — Edit tool can introduce U+2018/U+2019 as JS delimiters; use Python byte-level writes for JS string literals with apostrophes
- [Always use create-pr for any PR](feedback_use_create_pr_always.md) — use `create-pr` (not raw `gh-as-agent ... pulls`) for all PRs, including ad-hoc proactive fixes; it handles supervised-repo lucas42 reviewer request automatically
- [Contrast ratio verification](feedback_contrast_ratio_verification.md) — never assert a specific contrast ratio in a PR test plan from hand calculation; verify with WebAIM first (hand calc gave 3.05:1 for #c49000, correct is 2.86:1 — caused CHANGES_REQUESTED)
- [Pull architect back in on schema scope changes](feedback_pull_architect_on_schema_scope_changes.md) — a scope change that looks like a small UI subtraction can undercut the architect's original data-model justification; re-consult, don't shrink the schema myself (photos#471)
- [Verify accessible-name computation in a real browser](feedback_verify_accname_in_browser.md) — a new aria-label on a child can silently override a parent link's `title` fallback; test with Playwright's ariaSnapshot before/after, don't trust a static per-element reading (photos#476)

## Project

- [SW health pattern](project_sw_health_pattern.md) — SW-backed UIs (seinn) can degrade silently; pattern for surfacing SW health + guided recovery in UIs
- [CSP data: URI img-src](project_csp_data_uri_img_src.md) — CSS background-image data: URIs need `img-src data:` explicitly; style-src alone isn't enough
- [lucos_photos person-flag pattern](project_lucos_photos_person_flag_pattern.md) — standing judgements on `Person` are a plain nullable column + PUT/DELETE pair (`is_background`, `flagged_at`), not a table; #473 tracks the half-built profile-picture override
- [lucos_photos profile-picture surface](project_lucos_photos_profile_picture_surface.md) — rare per-item actions go on the detail page, not smeared across a grid; undo goes next to the visible problem, not the original action (photos#473)
- [lucos_photos profile-picture states](project_lucos_photos_profile_picture_states.md) — none/broken states collapse visually; a "pending" 3rd state needs a genuinely new signal — verify worker write-order before assuming otherwise, don't guess (photos#476)

## Reference

- [arachne MCP entity counts](reference_arachne_mcp_counts.md) — `list_types` inflates counts via OWL inference; use `find_entities` result count for precision
