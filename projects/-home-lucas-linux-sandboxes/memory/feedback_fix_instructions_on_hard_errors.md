---
name: Fix instructions on recurring hard errors
description: When hitting a hard error during a routine operation, update instructions immediately rather than waiting to be told
type: feedback
---

When you hit a hard error during a routine operation (e.g. tool limitation, API constraint) that will likely recur in future runs, update the relevant instructions immediately — don't just save a memory and move on.

**Why:** The user had to prompt me to update the `/team` skill after I hit the same broadcast error on every shutdown. I should have fixed the instructions the first time I hit it, without being asked.

**How to apply:** When a routine operation fails due to a structural constraint (not a transient error), immediately: (1) work around it, (2) update the relevant skill/persona/instruction file to prevent recurrence, (3) commit and push. Don't wait for the user to notice the pattern.
