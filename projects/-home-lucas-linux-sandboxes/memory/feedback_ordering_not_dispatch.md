---
name: Ordering advice is not a dispatch instruction
description: Teammate ordering guidance informs queue sequencing but does not authorise the coordinator to dispatch work autonomously
type: feedback
originSessionId: d4be6eb0-4d42-4175-8138-0723a9b2bb70
---
Ordering advice from teammates (e.g. "please pick these up in this order") should inform how issues are sequenced and labelled — but it is NOT a dispatch instruction. The coordinator should only dispatch based on explicit user requests (e.g. `/next`, `/dispatch`, an ad-hoc URL) or explicit user direction in conversation.

**Why:** The user expects to control when work is dispatched. Treating teammate sequencing guidance as dispatch authorisation means work gets kicked off without the user's knowledge or sign-off, which is undesirable.

**How to apply:** When a teammate provides ordering guidance alongside raised issues, triage the issues (apply labels, set dependencies, add to board) — but do not dispatch any of them unless the user explicitly asks (e.g. via `/next` or a direct dispatch request).
