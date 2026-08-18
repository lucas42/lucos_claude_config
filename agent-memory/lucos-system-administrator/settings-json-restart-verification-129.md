---
name: settings-json-restart-verification-129
description: lucos_claude_config#129 item 2 pending check — does settings.json stay byte-identical across a fresh Claude Code session start?
metadata:
  type: project
---

`settings.json` is now tracked directly (lucas42's decision, `3f2478d`, lucos_claude_config#127 §7 correction) rather than a canonical/materialise split. Whether that keeps `git status` clean depends on whether Claude Code rewrites the file identically at every session start (a "fixed point") or re-dirties it each time.

**Baseline recorded 2026-08-18** (before any session restart since `3f2478d`): `git hash-object settings.json` = `bda9406b0bfe21d103768b14a1070ebbbe47bb6d`, mtime `2026-08-18T20:21:21+01:00` (matches origin/main).

**Why unverified:** the test needs a genuine fresh Claude Code session start, which can't be triggered or observed from inside a running session — I looked for a way (spawning a subagent, etc.) and concluded none of them reproduce the actual "new session launch" event the mtime evidence pointed at.

**How to apply:** whoever next starts a fresh session (new `/team` invocation, VM restart, etc.) should run `git hash-object settings.json` before touching anything and compare to the baseline above. Two branches:
- Byte-identical → lucos_claude_config#129 item 2 is finished, nothing further.
- Different → the sweep needs extending to cover `settings.json`, which reopens the dormant security note in #127's assessment (a `Stop` hook + `permissions.defaultMode` going into an auto-committed path needs deliberate review before that ships).

See also [[project_head_drift_fix_127]].
