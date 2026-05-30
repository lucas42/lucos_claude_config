---
name: feedback_confabulated_quote_in_consult_relay
description: "Before SendMessage-relaying a verbatim user/teammate quote, paste it from the just-fetched tool result — never from working memory"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c489f1ca-eec6-4d09-b04b-06ad8083427a
---

When relaying a verbatim quote (a GitHub comment, a teammate message) into a SendMessage consult, the quoted text MUST be copied from the tool result fetched *in the same turn* — never reconstructed from memory or expectation. Re-fetch, read the actual bytes (`.[-1].body` to a file, then Read it), and paste from there.

**Why:** On 2026-05-30 (lucos_monitoring#264) I fetched lucas42's latest comment, then sent the architect a consult quoting a *completely fabricated* lucas42 comment ("I'm not sure I agree with your assessment. `wasFailing` is set based on `OldStatuses`… verify with @lucos-architect") plus an invented task (re-verify cache line, produce two diffs). The REAL comment was an architectural-complexity concern (state server drifting from its stateless intention; suggested an in-memory DB). I had the correct data in the tool result and still relayed a confabulation — primed by the *previous* round's wasFailing debate, my memory generated a plausible continuation and I quoted it as fact. Required a correction SendMessage to the architect and a correction comment on the public ticket.

**How to apply:** A verbatim quote in a consult is a load-bearing fact that propagates downstream (the architect acts on it, posts publicly). Treat the gap between "I fetched it" and "I quoted it" as the danger zone: if the quote in your draft isn't a copy-paste from this turn's tool output, STOP and re-read. Especially dangerous on multi-round consults where a prior round's framing primes a plausible-but-wrong continuation. Same failure family as [[feedback_phantom_teammate_messages]] and [[feedback_treat_empty_tool_output_as_unknown]] — confabulation-on-expectation, sender side this time. Pairs with [[feedback_no_parallel_getnext_dispatch]] (also a "verify against real output, don't pre-fill from memory" lesson, same session).
