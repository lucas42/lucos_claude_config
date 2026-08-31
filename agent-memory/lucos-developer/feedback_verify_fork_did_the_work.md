---
name: feedback_verify_fork_did_the_work
description: A forked/spawned agent's first completion can be a no-op acknowledgment (0 tool uses) rather than actual work — check before trusting the report
metadata:
  type: feedback
---

When delegating heavy mechanical work to a forked agent (e.g. `Agent` with `subagent_type: "fork"`), its "completed" task-notification is not proof it did anything. On lucos_monitoring#307 (splitting a 2281-line Erlang file into 6 files), the first fork call returned "completed" in ~3.5s with 0 tool uses — it just echoed back an acknowledgment of the plan instead of executing it. Re-sending the same instructions via `SendMessage` to the same agent id got it to actually do the work (35 tool uses, ~8 minutes).

**Why:** no visible cause found — possibly a race with a `ScheduleWakeup` call issued in the same turn, or the fork treating a long, detailed prompt as something to summarize rather than execute. Not reproduced a second time on the same session (the resumed run worked correctly), so this looks like an occasional failure mode rather than a systematic one.

**How to apply:** after any fork/subagent task-notification reports "completed", check the `usage.tool_uses` count (and rough duration) before trusting the result. A near-zero tool-use count on a task that clearly required file reads/writes is a signal the agent didn't actually execute — resume it with `SendMessage` to the same agent id/name, explicitly telling it to use its tools now, rather than assuming the reported "completion" text is accurate. This is separate from and in addition to independently re-verifying the *content* of what a fork claims to have done (tests, diffs, grep) before building on it — see [[feedback_no_unverified_endorsement]].
