---
name: Re-fetch immediately before any accusatory SendMessage
description: When a coordinator message contains a factual claim about another agent's GitHub state, re-fetch the state right before pressing send — not at the start of composing the reply
type: feedback
originSessionId: 4595a1b0-a470-4c5f-8870-6b813937dcbd
---
When composing a coordinator message that contains a factual claim about another agent's GitHub state ("you haven't pushed", "no new commit", "requested_reviewers is empty", "the persona updates aren't committed"), the verifying fetch must be the **last step before SendMessage** — not the first step of composing the reply.

**Why:** Multi-paragraph correction messages take 30+ seconds to compose. Agents push concurrent updates during that window. A fetch from the top of the reply is stale by the time the message hits the inbox, producing a false-positive accusation. The coordinator persona has had a "Verify before accusing" rule since 2026-04-30 to address this; the rule was skipped on 2026-05-11 for a developer correction about PR #228, producing a likely false claim that the fix hadn't been pushed when it had (or had been pushed concurrently with my message composition). The developer pushed back and was, on balance, right — the end state showed the fix in place. Two consecutive sessions hitting the same failure mode means the rule isn't structural enough; it needs a sharper trigger.

**How to apply:** Before pressing send on any coordinator message that includes a specific factual assertion about another agent's GitHub state, do the relevant fetch ONE MORE TIME — even if you already fetched at the start of composing. If the new state differs from your draft message's claims, rewrite the message to match. If you find yourself thinking "I already checked", that's exactly the trigger to check again. The fetch is cheap; a false accusation is expensive and erodes trust.
