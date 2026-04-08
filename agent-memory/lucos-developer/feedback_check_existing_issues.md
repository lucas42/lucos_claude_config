---
name: Check existing issues before filing new ones
description: Always search open issues on a repo before raising a new one to avoid duplicates
type: feedback
---

Always check existing open issues before filing a new one — other agents (sysadmin, code-reviewer, SRE, security) may have already filed the same finding.

**Why:** Three issues raised during a lucos_media_* ecosystem review were closed as duplicates of issues already filed by lucos-system-administrator and lucos-code-reviewer.

**How to apply:** Before calling `gh-as-agent ... /issues --method POST`, run `gh-as-agent ... /issues` (GET) and scan for any existing issues that cover the same finding. If a close match exists, skip filing. If unsure, check the issue title and body rather than just the title.
