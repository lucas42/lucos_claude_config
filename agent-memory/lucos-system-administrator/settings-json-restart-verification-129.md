---
name: settings-json-restart-verification-129
description: RESOLVED 2026-08-20 — settings.json's mtime/hash are stable across genuine fresh Claude Code process launches; lucos_claude_config#129 item 2 confirmed, no code change needed
metadata:
  type: project
---

**RESOLVED 2026-08-20, CONFIRMED branch.** `settings.json` stays byte-identical across a real fresh Claude Code session start — no re-dirtying, no sweep extension needed, the dormant security note in #127/#129 about auto-committing `settings.json` never activates.

**Evidence, direct not inferred:** baseline recorded 2026-08-18 — hash `bda9406b…`, mtime `2026-08-18T20:21:21.902717864+01:00`. Checked again 2026-08-20 from inside my own freshly-launched process (`ps -p $$ -o lstart=` → `Wed Aug 19 22:53:48 2026`, ~26.5h after baseline) plus six sibling teammate processes launched in the same window (`ps -eo pid,lstart,cmd | grep claude.exe`): hash and mtime on both `settings.json` and `origin/main`'s copy are still exactly the baseline values, to the nanosecond. A rewrite producing identical bytes would still move the mtime via `write()` — it hasn't, across ≥7 independent launches spanning >24h. So Claude Code either doesn't rewrite the file at session start, or writes it idempotently without touching mtime; either way the observable the ticket cares about (byte-stability across restarts) holds.

**Method note for future similar questions:** "was this genuinely fresh-launched" is answerable from inside a session via `ps -p $$ -o lstart=` compared against the harness's own process-start time — no need to spawn anything or wait for an external restart event. This unblocks what the original memory entry called unverifiable from inside a running session.

See also [[project_head_drift_fix_129]] if created, [[project_head_drift_fix_127]].
