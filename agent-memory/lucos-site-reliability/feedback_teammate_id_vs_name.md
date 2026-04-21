---
name: teammate_id is not the SendMessage name
description: Don't echo the `teammate_id` attribute from incoming message envelopes when replying via SendMessage — it's a harness-internal id, not the canonical persona name
type: feedback
---

When a message arrives wrapped as `<teammate-message teammate_id="code-reviewer-agent" ...>`, the `teammate_id` attribute is a harness-internal identifier and may differ from the canonical persona name used for `SendMessage`. Always use the canonical name (e.g. `lucos-code-reviewer`, `team-lead`, `lucos-security`, `lucos-site-reliability`) — **not** whatever string sits in the envelope's `teammate_id`.

**Why:** 2026-04-21 — replied to a code review reply by sending to `code-reviewer-agent` (the envelope's `teammate_id`) instead of `lucos-code-reviewer` (the canonical persona). Message went to the wrong inbox. The user had to correct me.

**How to apply:** Before every `SendMessage` call responding to an incoming teammate message, verify the `to:` field is a canonical persona name (matches a file in `~/.claude/agents/*.md` or is `team-lead`). Do not trust the envelope's `teammate_id` — it may be a UUID-style identifier or harness alias.

**Instruction update:** Added the canonical-name note to `common-sections-reference.md` and the SRE persona file on 2026-04-21. Other persona files need the same update during the next consistency audit by lucos-system-administrator.
