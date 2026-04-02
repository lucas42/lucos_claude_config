---
name: Complete agent consultation inline during triage
description: Don't park issues as "needs-design" when agent input is needed — do the consultation inline and finish the triage
type: feedback
---

When triaging an issue that needs input from another agent, do the consultation inline as part of the triage pass. Message the agent, wait for their response, then re-assess and finish triaging the issue. Do not label it `status:needs-design` and move on — that leaves the issue in limbo.

**Why:** The user pointed out that "needs design" is not a valid parking state. If waiting for lucas42's input, use `status:awaiting-decision`. If waiting for an agent, just ask the agent and wait — the triage isn't complete until the consultation resolves.

**How to apply:** During triage, if an issue needs agent input:
1. Message the agent inline (SendMessage)
2. Continue triaging other issues while waiting
3. When the agent responds, re-read the issue and finish triaging it
4. Only then is the issue fully triaged
