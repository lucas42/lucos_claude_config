---
name: lucos-media-seinn-mocha-regression
description: lucos_media_seinn recurring Dependabot major-group regression — mocha downgrades to 11.3.0, post-fix recurrence documented in #466
metadata:
  type: project
---

Dependabot's major-group update PRs for lucos_media_seinn consistently produce a lock file that downgrades `mocha` from `11.7.x` (on main) to `11.3.0`, dragging in `diff@5.2.2` (vs main's `7.0.0`) and `workerpool@6.5.1` (vs main's `9.3.4`). `npm ci` then fails because the lock file is inconsistent with `package.json`'s `mocha@^11.7.x` constraint.

**History:** 5 closed-without-merge occurrences in 7 days: #446, #452, #458, #461 (all 2026-05-16–2026-05-21), plus #465 (2026-05-22, currently open as live reference).

**Issue #462** (opened 2026-05-21, now CLOSED): lucos-developer identified the root cause as a global `"minimatch": "^5.1.7"` override in `package.json` forcing mocha@11.7.x to use incompatible minimatch. Fix applied 2026-05-21T08:34Z (global override removed).

**Issue #466** (opened 2026-05-22, OPEN): The fix from #462 did NOT fully resolve the major-group regression. PR #465 was opened AFTER the fix and still shows the same broken lock file. Possible residual cause: the `"folder-hash": { "minimatch": "^7.4.7" }` override still present, or a conflict from one of the other major bumps (lru-cache 5→11, commander 2→14).

**How to apply:** Do NOT close major-group regression PRs on this repo — there have been 4+ prior closes and close-and-recreate is not solving the root cause. Post a COMMENT review noting CI failure, link to #466, and leave the PR open as a live reference. `@dependabot recreate` will NOT help (same inputs = same broken lock file). Check #466 for investigation status before deciding any other action.
