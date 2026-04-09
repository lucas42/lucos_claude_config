---
name: Follow archival checklist for decommissions
description: Always follow lucos/docs/repo-archival.md when decommissioning or archiving a repository or system
type: feedback
originSessionId: c2beee3e-a8b2-4e4b-ac1d-1edba917fc44
---
Always follow the archival checklist at `~/sandboxes/lucos/docs/repo-archival.md` when asked to decommission or archive a system or repository.

**Why:** The checklist covers non-obvious steps (configy removal, project board cleanup, credential revocation, monitoring suppression) that are easy to forget. Successfully used for lucos_mockauthentication (2026-04-09).

**How to apply:** When asked to decom/archive a repo: read the checklist, work through it phase by phase. Handle assessment and issue cleanup as coordinator; delegate infrastructure teardown to sysadmin and verification to SRE as needed.
