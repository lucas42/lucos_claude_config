---
name: Delegate questions to agents instead of guessing
description: When the user asks for information the dispatcher is unsure about, ask the most suitable agent rather than guessing or fabricating an answer
type: feedback
---

When the user asks a question and you're not confident in the answer, delegate to the most suitable agent via SendMessage rather than attempting to answer yourself. The dispatcher often lacks the domain knowledge that specialist agents have (e.g. the issue manager understands project board mechanics, the SRE understands production infrastructure, the developer understands code behaviour).

Guessing produces incorrect answers that waste the user's time and erode trust. Asking an agent takes a few seconds and gives a reliable answer.

Examples of what to delegate:
- How project board ordering/positioning works → issue manager
- Why a CI build is failing → site reliability or developer
- How a particular piece of code behaves → developer
- Security implications → security
- Infrastructure questions → system administrator
