---
name: Don't overclaim attributions in incident reports
description: When writing an incident report's Detection / triage / What Was Tried sections, restrict claims about what others said or thought to verbatim or near-verbatim quotes — never attribute a hypothesis to someone unless they actually advanced it
type: feedback
---

When documenting an incident, **restrict attributions to what someone actually said**. Distinguish:

- "X identified Y as the trigger" → only if they actually said that
- "X framed the problem as Z" → only if they actually advanced Z as a hypothesis

The risk pattern: you (the responder) layer your own initial hypothesis on top of someone else's narrower observation, then later write the report attributing the combined framing to them. The report then becomes the permanent record of an opinion they never held.

**Why:** lucas42 raised this 2026-05-07 on incident report PR #133 / PR #134. The report had said:

> lucas42's hunch ("the language-family load might be the trigger") was correct on the trigger but framed the problem as load-related; the actual cause was structural URL semantics.

He had only said the load was the trigger (correct). The "load-related mechanism" framing that delayed the structural diagnosis was MY (SRE's) initial hypothesis on top of that. The original wording put my error onto him.

**How to apply:**

1. When writing about what someone said during an incident, quote them verbatim or near-verbatim. If the quote needs paraphrasing, keep the paraphrase narrow — don't extend the claim.
2. Separate "what X said" from "how I/we acted on it." If your own framing on top of their observation contributed to a delay, say so explicitly: "X said the load was the trigger; SRE's own hypothesis on top of that — that the mechanism was load-related — was what delayed the structural diagnosis."
3. The "Detection / triage" and "What Was Tried That Didn't Work" sections are the most likely places this slips in. Re-read them before opening the PR with attribution-mode lenses on: for each first-name/role mention, ask "did they actually say or do that?"
4. Same rule applies to attribution in GitHub comments, PR descriptions, and SendMessage to team-lead — but the incident report is the most damaging place for this kind of misattribution because it's the permanent record.

**Cross-link:** the broader "verify before stating" pattern — see the existing memory rule about cross-checking teammate claims via durable source-of-truth. This is the same shape applied to attributions of speech/opinion within prose.
