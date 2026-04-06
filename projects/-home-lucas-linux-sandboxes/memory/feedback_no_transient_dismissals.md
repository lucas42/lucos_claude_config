---
name: No transient dismissals in summaries
description: Never dismiss unhealthy systems as "transient" — always name the systems, the cause, what clears the alert, and when
type: feedback
---

When summarising ops check results, never repeat vague dismissals like "transient" or "should self-heal" from agent reports. For every unhealthy or alerting system, the summary must include: which specific systems are affected, the root cause, what will clear the alert, and when that's expected.

**Why:** The user dislikes transient errors being hand-waved away. "4 transient" is not useful — it hides which systems are broken and whether anyone needs to act.

**How to apply:** When compiling the routine summary, if an agent's report uses vague language about failures, push back and ask for specifics before including it in the summary. If the agent has already reported, rewrite their findings with concrete detail rather than parroting "transient."
