---
name: feedback-cross-persona-instruction-edits
description: Don't plan to edit another persona's instruction file myself — coordinate with them; on-disk edits don't refresh a running agent's session context
metadata:
  type: feedback
---

Never include "I'll trim/edit `agents/<other-persona>.md`" as one of my own action items in a
ticket or plan — even when the edit is small, mechanical, and clearly downstream of work I did
(e.g. pointing a persona's section at a new shared reference I created).

**Why:** caught by team-lead on lucas42/lucos_claude_config#141 before I acted on it. My ticket's
"What to do" had me trimming `agents/sre-circleci-api.md` (an SRE-owned file) once a new shared
reference existed. The standing rule (from lucas42/lucos_claude_config#133's decision) is that an
agent updates its own instruction file, because an on-disk edit does not update a running agent's
context — a trim made underneath `lucos-site-reliability` would leave that persona's session
working from the untrimmed text for the rest of its life. Team-lead resequenced the ticket instead:
shared rule lands first → I coordinate the SRE's trim *with* them once there's a reference to point
at → my own memory file last.

**How to apply:** when a remediation plan or issue body spans multiple personas' files, sequence it
so each touched file is edited by (or done live with) the persona that owns it — list "coordinate
with X once Y exists" as the action, not "I will edit X's file." This is easy to drop once the
visible deliverable (the shared paragraph, the new reference file) is written, since it's the less
visible half of the work — flag it explicitly rather than letting it become an implicit TODO.
