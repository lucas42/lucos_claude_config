---
name: agents-handle-one-actively-worked-issue-at-a-time
description: "Implementation personas (developer, architect, etc.) take one ticket at a time only while actively engaged on it. Once a PR is open and awaiting review, they are free to take the next issue — the dispatcher should NOT wait for the full PR review/merge cycle to complete."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0694212f-c284-4440-b728-8b4de27dae48
---

The constraint is per-active-work, not per-session or per-PR-lifecycle: each agent should only be **actively working** on one issue at a time. "Actively working" means investigating, implementing, or addressing reviewer feedback — it does NOT include idle time spent waiting for lucas42's review or for a PR to merge.

**Why:** Context bleeds between concurrent issue work when an agent is mid-implementation, so two simultaneous in-flight implementations produce poor quality. But once an agent has opened a PR and handed it off for review, they have no further immediate task on that issue until reviewer feedback arrives — so they are free to start the next issue. Treating the whole PR review/merge cycle as a blocking gate would idle agents unnecessarily, especially on supervised repos where lucas42's review can take hours or days.

**How to apply:**
- After dispatching an issue, the agent is "busy" until their PR is open and their substantive summary reply lands. That is the dispatchable-again signal — NOT PR-merged.
- Do not stack dispatches during active implementation work. Wait for the PR-opened + summary signal first.
- If reviewer feedback comes back asking for changes, the agent is busy again until those changes are pushed — don't dispatch new work to them during a back-and-forth review cycle.
- This rule applies to all implementation personas (developer, architect, security, sysadmin, UX, SRE), not just the developer.

Related: [[feedback_developer_message_queue]] covers the narrower "don't send follow-up messages in quick succession" rule about message-processing order.
