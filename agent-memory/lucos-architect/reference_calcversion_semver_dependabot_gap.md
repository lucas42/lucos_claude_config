---
name: calcversion-semver-dependabot-gap
description: How lucos image/package semver is computed (orb calc-version from conventional commits) and the estate-wide gap that dependency-major bumps never major the artifact
metadata:
  type: reference
---

**How lucos releases get their version:** the `lucos/deploy` orb's `calc-version` command (`lucos_deploy_orb/src/commands/calc-version.yml`) computes semver from **conventional commit messages** in the range since the last `v*` tag: `BREAKING CHANGE` or `^type(scope)?!:` → major; `^feat:` → minor; else patch. First release = `1.0.0`. Non-main branches get a `-pre.<sha>` suffix. Used by `release-docker`, `release-pip`, `release-npm`. No tags yet ⇒ no conventional-commit history needed.

**The estate-wide gap (uncovered 2026-06-07, in the now-decommissioned `lucos_scheduled_scripts` repo, issue #44):** the reusable Dependabot auto-merge workflow (`lucas42/.github` `reusable-dependabot-auto-merge.yml`) does `gh pr merge --auto --merge` for **all** Dependabot PRs (every semver level, no human gate), landing a **merge commit** with Dependabot's non-conventional `Bump the … group …` message. `calc-version` greps the range for a breaking token, finds none, so **a breaking *dependency* major only ever produces a patch bump of the artifact.** Any repo using calc-version + dependabot has this (docker images AND the pip/npm packages). Consequence: a base image / package can install a breaking dependency and release it as a patch, silently breaking downstreams that trust the major.

**How to apply:**
- When reasoning about whether an artifact's semver reflects its real breaking changes, remember it only reflects *conventional-commit* breaking changes in the repo's own history — not breaking changes pulled in via dependency bumps.
- The fix for "dependency-major should major the artifact" is to inject the right conventional-commit token on Dependabot PRs (via `dependabot/fetch-metadata` update-type → `feat!:`/`feat:`/`fix:`). Because the gap is general, the automated fix belongs in the shared reusable-auto-merge workflow / orb, not per-repo.
- Reusable sub-lesson (the original instance, `lucos_scheduled_scripts`, was decommissioned 2026-06-07): a **base image that does an unpinned `pip install` of clients its downstreams already declare in their own Pipfile** is largely redundant *and* non-reproducible — the redundancy compounds the calc-version gap because the base image can silently re-release a breaking client as a patch. Watch for this shape on any future shared base image, not just the retired one. See also [[check-protocol-contract-before-accepting-break]] (ADR-0011, the consumer-side counterpart).
