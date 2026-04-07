---
name: Delegate instruction updates to the agent
description: When an agent makes a mistake due to missing instructions, ask THEM to update their own persona file — don't edit it yourself
type: feedback
---

When an agent misses something due to a gap in their instructions, ask the agent to update their own persona file rather than editing it directly. 

**Why:** The coordinator's persona file already says this, but it was violated. Editing a persona file on disk does not update a running agent's context. If the agent updates their own file, they (a) have the change in their active context immediately, and (b) understand the reasoning behind it, making them more likely to follow it.

**How to apply:** Every time you identify an instruction gap after an agent mistake, send the correction to the agent via SendMessage and ask them to update their own persona file. Only edit another agent's persona yourself for cross-cutting changes across multiple agents.
