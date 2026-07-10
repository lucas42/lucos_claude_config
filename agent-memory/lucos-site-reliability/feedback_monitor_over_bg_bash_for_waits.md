---
name: feedback-monitor-over-bg-bash-for-waits
description: For waiting on a production condition (deploy→green, sweep completes), use the Monitor tool, not Bash run_in_background sleep-loops — the latter were reaped ~2min in the agent sandbox
metadata:
  type: feedback
---

**When waiting on a production condition to resolve — a deploy landing, a sweep completing, a monitoring check flipping green — reach for the `Monitor` tool (poll loop with `sleep`, emit on terminal state + periodic heartbeat), NOT `Bash` with `run_in_background`.**

**Why:** During the 2026-07-10 lucos_repos#433 verification I launched several `Bash run_in_background` sleep-loops to watch the deploy → green transition. They were repeatedly **killed at ~2 min** with status `killed`/`stopped`, regardless of whether they printed every poll or deduped output — I couldn't isolate the trigger (one earlier loop *did* survive 22 min, so it's flaky, not a clean rule). I lost ~5 relaunch cycles before switching to `Monitor`, which ran the full ~15 min to completion without being reaped. The Bash tool doc *claims* background tasks "keep running across turns", but that was **not reliable** in this sandbox — treat it as unreliable for multi-minute waits.

**How to apply:**
- Multi-minute wait on a condition → `Monitor` with `timeout_ms` covering the expected window; emit only on terminal states + a heartbeat every ~5 iterations (avoids the "too many events → auto-stopped" cap).
- Cover **both** terminal outcomes, not just success — e.g. sweep-completes-green AND sweep-completes-still-failing — or the watch stays silent through a regression (silence ≠ success).
- **`seconds_since_last_sweep == -1` means a sweep is RUNNING** (none completed since container start), NOT "just completed" — my first Monitor exit-2 was a false WARN because I treated `-1 < 3000` as a completed sweep. A *completed* sweep gives a small non-negative value. See [[pattern_lucos_repos_deploy_triggers_sweep]].
- Prefer verifying a fix via the **deploy's own startup sweep** over a manual `POST /api/sweep` re-trigger when the failure mode is rate-limit-related — don't burn the same budget you're trying to stay under.
