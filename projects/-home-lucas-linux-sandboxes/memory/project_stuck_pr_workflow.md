---
name: Stuck PR workflow overhaul (2026-03-19)
description: New stuck-PR detection and resolution process added to agent instructions, with known stuck PRs left as a live test
type: project
---

On 2026-03-19, the routine exposed that agents were doing a poor job of resolving stuck PRs — shallow resolutions (filing backlog issues instead of fixing), no verification that actions worked, and incomplete detection criteria.

A new stuck-PR workflow was designed collaboratively (code reviewer, security, SRE, issue manager all contributed) and written into standing instructions across multiple persona files and the routine skill. Key changes:

- **Code reviewer** has 7 detection criteria (up from 3), post-approval verification, escalation routing table, and a rule to never approve with failing CI
- **Security** must verify `@dependabot` commands, fix immediately rather than deferring to backlog issues
- **SRE** has a codified code/plumbing boundary for escalation
- **Sysadmin** gained `actions: write` permission and can now re-run GitHub Actions workflows
- **Dependabot commands** (`@dependabot recreate/rebase`) are a GitHub platform limitation — no bot can run them, must route to lucas42

**Why:** The 2026-03-19 routine left 4 stuck PRs unresolved (lucos_navbar#39, lucos_root#43, lucos_photos_android#85, lucos_eolas#96). These were deliberately left unfixed so the next session can test whether the new instructions work cold, without context from the design conversation.

**How to apply:** If stuck PRs come up in a future session and agents struggle, the instructions may need further refinement. Check the persona files and routine skill for the stuck-PR sections. The test PRs may have resolved themselves by then (e.g. navbar#39 had its workflow re-run triggered), but if new stuck PRs appear, the process should handle them properly.
