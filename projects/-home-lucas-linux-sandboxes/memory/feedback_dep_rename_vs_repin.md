---
name: feedback_dep_rename_vs_repin
description: "When a dep bump breaks on a \"removed transitive\", check for a RENAME before re-pinning the old package name"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 94aa52c6-ab9a-4363-b96b-b947dcdadbad
---

When a Dependabot/lockfile bump breaks a build because a previously-bundled transitive dependency is "gone", **verify whether the upstream package was renamed** before fixing it by re-declaring the old name as an explicit dependency. The new version may bundle the *renamed* successor instead — re-pinning the legacy alias produces a technically-working but wrong fix that installs a phased-out package.

**Concrete case (2026-06-26):** webpack 5.108.0 broke the JS estate's builds. `webpack@5.100.0` bundled `terser-webpack-plugin@^5.3.11`; `webpack@5.108.0` bundles **`minimizer-webpack-plugin@^5.6.1`** — the same plugin renamed for webpack v5+ (both publish from `github.com/webpack/minimizer-webpack-plugin` at lockstep versions; `terser-webpack-plugin@5.6.1`'s own README is the minimizer README). The configs `import … from 'terser-webpack-plugin'`, so webpack no longer provided it. The first fix (code-reviewer diagnosis → dev) added `terser-webpack-plugin` as an explicit devDep — works, but re-pins the legacy name. lucas42 caught it: the right fix is to migrate the import to `minimizer-webpack-plugin` (the package webpack now ships).

**Why:** the coordinator relayed/dispatched a diagnosed fix without sanity-checking the *approach*. A cheap check — `npm view <pkg> repository.url` / readme, and `npm view webpack@<new> dependencies` — reveals a rename in seconds.

**How to apply:** for any "removed bundled transitive" diagnosis, before re-pinning, run `npm view <pkg> deprecated repository.url` and diff the new major's `dependencies` against the old to spot a renamed successor; prefer migrating the import to the new name. Relates to [[reference_issue_manager_no_pr_write]] (the close-not-recreate follow-on for the same PRs).
