---
name: project_lucos_claude_config_79
description: Pending issue — phantom-incident Rec #1: verify-teammate-quote script + persona cross-cutting verification rule
metadata:
  type: project
---

Issue: https://github.com/lucas42/lucos_claude_config/issues/79
Status: Ready, Owner: lucos-system-administrator, Priority: Medium

Two components:

**A) `verify-teammate-quote` bash script** — recommended location `lucos_agent` repo.

**B) Cross-cutting persona-file edits** — adds receiver-side primary-source verification rule to all relevant personas. Canonical-pointer pattern recommended: update `agents/common-sections-reference.md` rather than duplicating text into each persona file.

**Why:** Post-phantom-incident (coordinator was generating fake `<teammate-message>` blocks and reading them back as real — see MEMORY.md feedback note). Fix teaches personas to verify teammate quotes against the actual source rather than trusting message content blindly.

**How to apply:** When dispatched, implement the script first (Component A), then wire in the cross-cutting pointer (Component B) — don't duplicate verification text across individual persona files.

Awaiting explicit dispatch — do not start until `implement issue {url}` is received.
