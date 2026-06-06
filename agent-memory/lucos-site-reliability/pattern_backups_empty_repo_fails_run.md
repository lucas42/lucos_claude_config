---
name: pattern-backups-empty-repo-fails-run
description: create-backups check red because an empty (zero-commit) GitHub repo can't be tarball'd; volumes+other repos fine
metadata:
  type: project
---

`lucos_backups/create-backups` reports `success=False` (monitoring red) when the owner-repo list contains an **empty repository** (zero commits). `Repository.getAll()` lists all owner repos via `/user/repos`; `backup()` → `getAuthenticatedDownloadUrl()` returns a **ref-less** codeload URL for an empty repo (`…/legacy.tar.gz/`, trailing slash, no branch) → `wget` exit 8 → per-repo failure (caught + logged, run continues) → non-empty `failures` forces the failure tick.

**Diagnostic signature:** schedule-tracker debug = `"Backups failed for: repo:<name>"`; container log shows `UnexpectedExit … Command: 'wget "https://codeload.github.com/lucas42/<name>/legacy.tar.gz/" …' Exit code: 8`. codeload returns 400 (no ref) / 404 (declared default branch has no commits).

First hit 2026-06-06 via `lucas42/lucos_dns_secondary` (created 06-05 12:25, `size:0`, no commits — scaffolded for the DNS-secondary work, lucos#217). **Volume backups and all other repos are unaffected** (volumes run first and complete; only the empty repo fails) → no data-at-risk, but a persistently-red check.

**Self-clears** only when the empty repo gets its first commit; recurs for every newly-created empty repo. Proper fix = skip `size==0` repos in `getAll()`. Tracked: **lucos_backups#298**. If open on recurrence, comment, don't refile.

Diagnostic foot-gun: lucos_backups container logs are dominated by 10s-interval `/_info` access lines; `grep -v '/_info'` to find job output. Logs roll off fast — a dependabot deploy recreates the container and wipes history.

Related: [[pattern_three_stage_env_var_wiring]], fd-leak incident 2026-06-03 (lucos_backups#291, closed, fix in PR #294 deployed 06-03).
