---
name: Question whether an agent-raised issue should exist before triaging it
description: Before applying labels to a new agent-raised issue, ask if it duplicates an existing tracking surface (Dependabot/CodeQL/monitoring alerts) with a fully automated resolution path
type: feedback
originSessionId: 061afd69-ccf3-4111-8b35-6aba5d24e6a8
---
When a teammate agent (especially security or sysadmin doing ops checks) raises a GitHub issue, do not reflexively triage it. First ask: does this issue duplicate an existing tracking surface (Dependabot alert, CodeQL alert, secret-scanning alert, monitoring alert, lucos_repos convention failure) AND is the end-to-end resolution path fully automated with no human-actionable step in the middle? If yes, push back to the raiser and close the issue rather than applying labels.

**Why:** lucas42 questioned `lucos_backups#270` (paramiko CVE-2026-44405, 2026-05-09): a low-severity CVE with no upstream patch yet, where Dependabot would auto-PR once a release shipped, CI would run, auto-merge would fire, and the alert would close automatically. The GitHub issue duplicated the alert without enabling any human action the alert wouldn't have enabled. I had triaged it (labels, project board, comment) without questioning whether it should exist — the security agent's own framing "Dependabot will auto-PR when a patch ships" was itself the signal that no separate issue was warranted, and I missed that signal.

**How to apply:** Now codified in `~/.claude/references/triage-procedure.md` under "Inline Triage of Agent-Raised Issues" → "Pre-flight: should this issue exist at all?". Three-condition test: canonical surface exists outside GitHub Issues + automated resolution path + body says "wait for upstream" or similar. When all three hold, do not apply labels — close as `not_planned`, message the raiser to update their standing instructions, remove from board.
