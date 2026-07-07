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
**Follow-ups filed:** #2 setup/build (Blocked: needs ADR sign-off + aithne OIDC client reg, prod secret lucas42-only), #3 phase-2 wikilinks (BookStack References panel may already cover it), #4 map tool build-in-vs-link-out (candidate future `lucos_atlas`), #5 data export, #6 `/_info` monitoring gap.

**Process note:** `check-unsupervised` errors (exit 2, "not found in configy") on a brand-new repo not yet in configy — the situation for every founding ADR. Default to draft PR in that case. Flagged to coordinator for a persona/workflow instruction line. Empty repo (no base branch) needs `main` bootstrapped (minimal README) before a PR can exist.
