---
name: Don't act on ambiguous user replies — ask
description: When a user's reply could plausibly answer either of two questions you posed, ask which they meant. Especially watch for parallel-labeling collisions across sections of your own messages.
type: feedback
originSessionId: 061afd69-ccf3-4111-8b35-6aba5d24e6a8
---
When the user's reply could plausibly answer either of two open questions, do not guess. Ask which question they were answering before acting on it.

**Why:** On 2026-05-09 I sent the user a message with three sections, each presenting decisions. Section 1 used `(a)/(b)/(c)` for a security-runbook-callout dispatch, section 2 used `Option A/B/C/C1/C2` for the architect's diagnostic options, with Option A from architect already shipped. The user replied "Option A sounds fine to me" — they meant the architect's Option A (i.e. "stick with what's shipped, no further B/C work"), not section 1's (a). I read it as approving both, and dispatched security to write a PR they hadn't directed. Worse, the user's reply was timestamped before SRE's relay-of-security's input had even arrived in my inbox, so they couldn't possibly have been answering both questions. Lazy reading on my side, plus a structurally ambiguous message format on my side.

**How to apply:** Two preventative habits:
1. **Don't reuse label families across sections of one message.** If section 1 uses `(a)/(b)/(c)` and section 2 uses `A/B/C`, a user reply naming "A" or "(a)" is structurally ambiguous. Pick one labeling scheme per message, or use distinct disjoint families (e.g. numbered options in section 1, lettered in section 2). Better still: don't load a single message with multiple decisions if you can avoid it.
2. **When the reply is ambiguous, ask.** Cost of a clarifying question is one turn. Cost of guessing wrong is dispatched work the user didn't ask for, which I then have to retract.

Watch for the timing tell too: if the user's reply timestamp predates a piece of input you've folded into your message, they cannot have been responding to that input. Use that to disambiguate.
