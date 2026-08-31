---
name: lucos-claude-config-147-return-to-main-fixture
description: return-to-main.sh's CLAUDE_DIR and LOGANNE_EVENT_SCRIPT parameterised; new fixture test in scripts/tests/
metadata:
  type: project
---

`lucos_claude_config`#147: RESOLVED 2026-08-31, PR #156 merged. `scripts/return-to-main.sh`'s `CLAUDE_DIR` and `LOGANNE_EVENT_SCRIPT` are now env-overridable (defaults unchanged). New `scripts/tests/return-to-main-fixture-test.sh` builds a disposable local bare repo + working checkout and exercises all three jobs (branch-switching, sync + `materialize_pr_content`'s three cases, persistent-dirt detection/clearing, sync-failure tracking/recovery) — 11 checks, run by hand (no CI in this repo).

**Why `LOGANNE_EVENT_SCRIPT` had to be parameterised too:** it's a second, independent hardcoded path (not derived from `CLAUDE_DIR`) posting to the live Loganne endpoint. A fixture overriding only `CLAUDE_DIR` would fire a real production event the moment it deliberately exercised the alerting path — the exact behaviour most worth testing. General pattern: when isolating a script for fixture testing, grep for *every* hardcoded absolute path, not just the obvious one.

**Verification pattern worth reusing:** sabotaged a real code path (`materialize_pr_content`'s `mv` step) on a scratch copy and confirmed the fixture suite actually fails (3/11) before trusting a green run — proves the tests have discriminating power, not just happy-path rehearsal. Reviewer independently repeated this against a different code path (the `disk_hash==old_hash` guard) and got matching results.

**Step 11 note:** `~/.claude` is the live checkout for this repo and syncs itself via `return-to-main.sh` (Stop hook / 15-min cron) — never run git against it directly; just wait and verify file content on disk, per the workflow's own carve-out.
