---
name: project-lucos-worlds
description: lucos_worlds worldbuilding system — adopt-BookStack founding decision, ADR-0001, follow-ups
metadata:
  type: project
---

**lucos_worlds** — private worldbuilding system for TTRPGs (originating brief: lucas42/lucos#248).

**Decision (lucas42, 2026-07-07): ADOPT BookStack.** Not self-build. Single-user (lucas42).
- **Why adopt over self-build:** requirements collapsed to something small (single user, 3 fixed types, wikilinks deferrable, per-item single image) → adopt cheaper. BookStack chosen over kanka/Outline/Wiki.js: MIT licence (clean), **native OIDC SSO** (clean aithne integration, no fork), Book→Page hierarchy fits worlds→items. The tension: kanka has the typed model but own-auth; SSO wikis have auth but no typed model — BookStack + types-as-tags was the trade.
- **Model mapping:** world→Book, item→Page, type→tag (`type=pc|npc|place`); Place hierarchy = informal content convention, NOT first-class types. Types are a soft (unenforced) tag convention.
- **Deploy shape:** thin wrapper image `lucas42/lucos_worlds_web` FROM pinned upstream BookStack + MariaDB (new DB engine in estate). Two stateful volumes (DB + file storage). Fantasy CSS version-controlled in repo (BookStack Custom HTML Head Content verified; file-based `APP_THEME` theme system to confirm at setup).
- **Honest negatives recorded:** don't own the code (upgrade/security tracking via pinned tag + Dependabot; no CodeQL); MariaDB new engine; no native `/_info` (monitoring gap); aithne hard dep.

**ADR-0001** = `docs/adr/0001-adopt-bookstack.md`, draft PR lucas42/lucos_worlds#1 (draft pending lucas42 sign-off; repo has NO CI/auto-merge yet → merge will be manual).
**Follow-ups filed:** #2 setup/build (Blocked: needs ADR sign-off + aithne OIDC client reg, prod secret lucas42-only), #3 phase-2 wikilinks (BookStack References panel may already cover it), #4 map tool build-in-vs-link-out, #5 data export, #6 `/_info` monitoring gap.

**#4 map tool RESOLVED → LINK-OUT** (2026-07-09, comment on worlds#4). BookStack has no first-party plugin API, so build-in = fork or fragile theme-injection, blowing up ADR-0001's no-fork thesis; the map editor itself costs the same either way (BookStack gives nothing towards it). Rec: separate deployed system. Repo **`lucos_worlds_atlas`** now exists (empty). Caveat flagged: if the real want is only "static map image + clickable pins", that's a small in-BookStack widget, not a system — scope is lucas42's to confirm. Eventual design = ADR-0001 in the atlas repo (new-system founding), gated on green-light.

**lucos_repos repo-type** (2026-07-09, architecture_models#3): `lucos_worlds_atlas` (empty future-system) + `lucos_architecture_models` (ADR-0008 "output sink, not a founded system") both trip `in-lucos-configy`. I proposed a 4th non-executable `docs` type; **lucas42 rejected — won't mint a type for one repo; use `script` as stopgap until a real pattern accumulates.** I assessed `script`: VIABLE. Adds only `reusable-workflow-pinned` (graceful skip, passes) + `dependabot-auto-merge-workflow` (hard-fails `content==nil`, NO skip → one standing false finding on a README-only repo). Clears the #3 finding that mattered. Tidy eventual fix offered: give `dependabot-auto-merge-workflow` the same no-workflows skip its sibling has (~3 lines). Do NOT add a "planned" type for future-systems either (see [[feedback_prefer_self_healing_finding_over_silent_suppression]]) — leave unconfigured until scaffolded.
**CORRECTION (verified c4.go):** the C4 generator consumes ONLY configy `systems` (fetchConfigySystems + /_info probe); component/script/non-system repos never enter the model. So a non-system mislabel is NOT a C4-data-corruption risk — that risk exists only for a *system* mislabel (triggers unreachable-/_info divergence). My earlier "mislabel feeds false fact to C4" claim was over-broad; corrected on #3.

**Process note:** `check-unsupervised` errors (exit 2, "not found in configy") on a brand-new repo not yet in configy — the situation for every founding ADR. Default to draft PR in that case. Flagged to coordinator for a persona/workflow instruction line. Empty repo (no base branch) needs `main` bootstrapped (minimal README) before a PR can exist.
