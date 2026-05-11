---
name: Developer takes one issue per session — don't queue
description: lucos-developer enforces one-issue-per-session and refuses additional dispatches while a PR review loop is in flight. Dispatch sequentially, wait for full completion.
type: feedback
originSessionId: 6ce34597-cfb3-4151-9e30-3c9c944f1aca
---
The lucos-developer agent has a standing rule: **no new issues in the same session until the active PR review loop completes.** Dispatching multiple "implement issue" messages in succession results in only the first being picked up; the rest are deferred and require re-dispatch from a fresh session.

**Why:** Context bleeds between concurrent issue work — quality suffers. The developer's own persona enforces this.

**How to apply:**
- After dispatching an issue to the developer, **wait for the full completion signal** (PR merged + dev's substantive summary reply) before dispatching the next.
- Do NOT attempt to "fill the queue" by sending all ready issues at once — the dev will reject all but the first.
- This applies even when the user has explicitly said "dispatch everything ready" or "don't block on inline questions". Their request for non-blocking refers to chat-level UI (AskUserQuestion etc.), not to overriding the developer's per-session limit.
- The proper sequence: dispatch → wait for `PR merged + dev summary reply` → dispatch next → repeat.
- If multiple ready issues belong to the developer, queue them mentally and dispatch one-at-a-time as each completes. The dev returning idle after a "review request sent" is NOT a completion signal — only the post-merge final summary is.

Related: [feedback_developer_message_queue.md](feedback_developer_message_queue.md) covers the narrower "don't send corrections in quick succession" case.
