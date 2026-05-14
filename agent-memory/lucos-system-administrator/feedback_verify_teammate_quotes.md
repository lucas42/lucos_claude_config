---
name: feedback_verify_teammate_quotes
description: Before quoting a teammate verbatim with attribution, run verify-teammate-quote to confirm it's real
metadata:
  type: feedback
---

Before quoting another teammate's prior message verbatim with attribution in a SendMessage, GitHub comment, issue body, or PR body, run:

```bash
verify-teammate-quote --sender <persona-name> --quote "<text>"
```

Exit 0 = verified (found in the sender's role:assistant output). Exit 1 = unverified — paraphrase, drop the attribution, or flag the discrepancy.

**Why:** The 2026-05-14 phantom-incident happened because `team-lead` generated fake `<teammate-message>` blocks in its own output and read them back as real inbound messages, producing false accusations. `lucos-site-reliability` caught it by pushing back on a claim that didn't match its own history. The script formalises that verification discipline.

**How to apply:** Fires when about to write "X said Y" / "per X: Y" / a blockquote attributed to X in any artifact. Does NOT fire for paraphrase or outcome-reporting.

Script lives at `~/sandboxes/lucos_agent/verify-teammate-quote` (on PATH for all sessions). Full rule: `references/teammate-quote-verification.md`. Implemented in lucos_claude_config#79 + lucos_agent#54.
