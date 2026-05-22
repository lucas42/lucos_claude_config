---
name: verify-sibling-repo-claims
description: Don't make load-bearing claims about a sibling repo's behaviour from memory. Read the actual code before propagating the claim into a SendMessage, issue body, PR body, or incident report.
metadata:
  type: feedback
---

When writing about behaviour of a service or library *other than the one immediately being investigated*, verify the claim against the actual source code before publishing it. The `verify-substantive-claims` rule already covers this in spirit, but it kept biting me on cross-repo factual claims so it deserves its own memory.

**Why:** On 2026-05-22 I built a "media-api's Go loganne client is the outlier; the Python client has retry semantics" argument into both a SendMessage to architect and the second-pass incident-report amendment. Architect actually read the Python client (`lucos_loganne_pythonclient/loganne.py`) and showed it doesn't — it's a single `try/except` around `session.post`, no retry, no timeout. My claim came from a vague recollection plus possibly conflating "loganne retries failed webhook *deliveries* once" (true, in `webhooks.js`) with "loganne *clients* retry their `POST` to loganne" (false, none of the four clients do). The reversal undermined a load-bearing chunk of the report and required a second-pass amendment to fix.

**How to apply:**

- When about to write "X has Y semantics" / "X retries" / "X does not retry" / "X has a timeout of N" for a repo other than the one I'm currently editing: read X's actual code first. Even if I "definitely remember" it.
- The standing "loganne retries webhooks once" memory at the top of MEMORY.md is about loganne re-firing failed *outbound* webhook deliveries. It is not a claim about clients retrying their *inbound* POSTs. Don't conflate.
- This applies most strongly to language-and-mechanism claims that feel like a "well, the convention is..." statement. Conventions across this estate are less uniform than I expect (today's table: Python no-timeout-no-retry, two different Go behaviours, Erlang no-timeout-no-retry). When a claim becomes a load-bearing assumption in a write-up, *read* the artefact.

Related: see [[feedback_verify_before_propagating]] (the existing version of this rule, weaker because it talks about identifiers — paths, URLs, repo names — not behavioural claims).
