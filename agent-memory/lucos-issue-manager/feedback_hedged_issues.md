---
name: Hedged security issues need specialist verification before approval
description: When an issue body contains hedging language about the correct fix ("should be confirmed", "probably only needs"), treat it as an unresolved question requiring specialist input before approving
type: feedback
---

Do not approve issues that hedge on the correct implementation approach. Phrases like "exact scopes should be confirmed", "probably only needs X", or "should be verified against what the code actually does" are unresolved questions, not minor caveats.

**Why:** In the lucos_repos#177 incident (2026-03-21), lucos-security[bot] suggested `permissions: pull-requests: write` + `contents: write` but hedged that scopes should be confirmed. I approved the issue without consulting a specialist. The correct value turned out to be `permissions: { contents: read }` — the reusable workflow uses its own App token, so the caller needs almost no permissions. The premature approval let the issue enter the implementation queue with a wrong scope value, requiring a course-correction comment from lucas42 before work could start.

**How to apply:** When triaging any issue (including well-specified CodeQL/security bot issues), scan for hedging language in the recommended fix. If present, consult the relevant specialist agent to resolve the question before marking `agent-approved`. This is especially important for issues involving reusable workflows, shared templates, or anything where the fix affects multiple repos — getting it wrong has a blast radius.
