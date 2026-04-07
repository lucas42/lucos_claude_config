---
name: Use sysadmin persona consistency audit for cross-agent changes
description: When adding or updating a common section across all persona files, update the reference then delegate to sysadmin
type: feedback
---

When making the same change across all persona instruction files, use the sysadmin's persona consistency audit rather than editing each file manually.

**Why:** The sysadmin already has a "Persona Consistency Audit" workflow that compares all persona files against `~/.claude/agents/common-sections-reference.md` and fixes drift. Doing edits manually is slower, error-prone, and duplicates existing capability.

**How to apply:** 1) Update the common-sections reference file with the new/changed section. 2) Send a message to `lucos-system-administrator` asking them to run a persona consistency audit. They will propagate the change to all personas and commit.
