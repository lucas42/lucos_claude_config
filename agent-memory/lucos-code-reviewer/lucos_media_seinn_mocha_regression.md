---
name: lucos-media-seinn-mocha-regression
description: lucos_media_seinn has a recurring Dependabot major-group regression where mocha downgrades from 11.7.5 to 11.3.0 — investigation open
metadata:
  type: project
---

Dependabot's major-group update PRs for lucos_media_seinn consistently produce a lock file that downgrades `mocha` from `11.7.5` (on main) to `11.3.0`, dragging in `diff@5.2.2` (vs main's `7.0.0`) and `workerpool@6.5.1` (vs main's `9.3.4`). `npm ci` then fails because the lock file is inconsistent with `package.json`'s `mocha@^11.7.5` constraint.

**Why:** Root cause unknown — Dependabot's resolution is generating an internally consistent but wrong lock file. Three PRs closed for this reason in 5 days: #446, #452, #461 (all 2026-05-21 window).

**Investigation issue:** https://github.com/lucas42/lucos_media_seinn/issues/462 (Owner = lucos-developer, Priority = Medium, opened 2026-05-21).

**How to apply:** When reviewing a Dependabot major-group PR on lucos_media_seinn that fails CI, check for this pattern first. Do NOT close another one — check issue #462 for status and link the new PR to it instead.
