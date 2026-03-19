---
name: Issue granularity feedback
description: lucas42 prefers not to split small, related findings into separate tickets
type: feedback
---

When a small permissions gap or fix is discovered while working on a related task, it should be handled within the existing context rather than filed as a separate ticket.

**Why:** lucas42 closed lucos#52 (GitHub Apps lack Actions write permissions) saying "This shouldn't have been a separate ticket." The permission was granted as part of the existing work; the separate issue was unnecessary overhead.

**How to apply:** When agents discover a small, actionable gap (like a missing permission) while working on something, prefer handling it inline or noting it on the parent issue rather than creating a new issue. Reserve new issues for genuinely independent work items. This especially applies to permission grants and infrastructure tweaks that are preconditions for a task already in progress.
