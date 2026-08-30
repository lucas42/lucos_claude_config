---
name: screenshot-catches-ordering-bugs-unit-tests-miss
description: Render a real screenshot of grouped/related-item UI, not just eunit/unit assertions — visual adjacency bugs pass per-item tests but read as broken
metadata:
  type: feedback
---

On [[project_monitoring_dependent_failure_grouping]] (lucos_monitoring#296/PR #306), the
classification logic (which system is a root cause vs. dependent) was correct and fully
covered by eunit tests — but the existing page sort was pure alphabetical-by-name within a
status group, so a dependent could render *above* its own root cause whenever it sorted
first alphabetically. Every unit test passed; the rendered page still read wrong, because
none of the tests asserted relative visual position between related items, only that each
item's own markup was correct in isolation.

**Why this matters:** grouping/hierarchy/adjacency features (root-cause clustering,
related-item lists, breadcrumbs, anything where the story is "these belong together") can
have 100% correct per-item logic and still fail the actual UX goal if the layout doesn't
place them adjacently. Unit tests assert properties of individual elements; they don't
naturally assert "element A appears immediately before element B in rendered order" unless
you specifically write that test — and you often don't think to until you *see* the bug.

**How to apply:** for any feature whose value depends on relative position or grouping
(not just per-item correctness), render a synthetic snapshot reproducing the shape that
motivated the feature and actually look at it (Playwright screenshot via
`~/sandboxes/lucos_agent/ux-tools/assess.mjs`, or a hand-rolled snapshot + screenshot for
services without a browser-facing dev server) before calling the work done. Do this even
when unit tests are green and even for a small, well-tested change — the ordering bug here
survived a passing 285-test eunit suite. Once caught, also add a regression test asserting
the relative position directly (e.g. `PosRoot < PosDependent` via `string:str/2`) so it
can't silently regress.
