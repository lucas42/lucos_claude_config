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

**RESOLVED 2026-06-07** — fix shipped in PR #301 (`if rawinfo['size'] > 0` filter in `Repository.getAll()`), deployed as v1.0.88 to avalon 14:20:22Z. Verified by ad-hoc end-to-end `create-backups` run (exit 0, "Backups Complete", zero failures, `lucos_dns_secondary` absent from the repo list); monitoring check flipped green. Class of bug closed; empty repos no longer break the run.

**Drive-by spotted in deployed code 2026-06-07** (NOT yet filed): `Repository.backup()`'s `host.connection.run("wget …")` has **no `timeout=`**, unlike the adjacent `mkdir` (`timeout=3`). A wedged codeload TCP connection would hang the run indefinitely while holding `/var/run/lucos_backups/create.lock` → all subsequent cron runs no-op on the lock → backups silently stop until someone kills the process (the 72h liveness check would eventually alert). Cheap one-line fix (add a `timeout` to the wget run). Flagged to team-lead; decision theirs.

Diagnostic foot-gun: lucos_backups container logs are dominated by 10s-interval `/_info` access lines; `grep -v '/_info'` to find job output. Logs roll off fast — a dependabot deploy recreates the container and wipes history.

Related: [[pattern_three_stage_env_var_wiring]], fd-leak incident 2026-06-03 (lucos_backups#291, closed, fix in PR #294 deployed 06-03).
