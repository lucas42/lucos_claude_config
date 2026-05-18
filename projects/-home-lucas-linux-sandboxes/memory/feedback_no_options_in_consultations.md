---
name: feedback-no-options-in-consultations
description: "When relaying a lucas42 design question to a specialist, do NOT add my own enumerated options or 'options I see' framing — relay lucas42's question verbatim and let the agent enumerate"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 43800831-9ee6-4716-b001-e07766f613bc
---

When SendMessaging a specialist (architect, SRE, security, sysadmin, UX) to consult on an open design question lucas42 raised, **relay his words verbatim and do not augment with my own option list, suggested approach, or "options I see (you may see others)" framing**. Even when I can think of plausible options, listing them is harmful — it biases the agent toward my framing and away from approaches outside my enumeration. "More obvious" defaults will dominate the agent's thinking once they're written down.

**Why:** On 2026-05-18 lucas42 raised problem-oriented questions on `lucos_media_metadata_api#237` and `lucos_media_metadata_api#240`. I relayed them to the architect with a list of options I'd thought of — "(a) default to Group, (b) default to Person, (c) require hint, (d) infer from metadata". lucas42 called it out: "I'd deliberately kept my questions problem-orientated... I'm worried you'll nudge them towards the more obvious answers, rather than keeping their mind open to all options." The instruction "Delegate the problem, not the solution" already existed in coordinator-persona.md; the failure was applying it specifically to specialist consultations.

**How to apply:** When composing a consultation SendMessage:

1. Quote lucas42's question verbatim.
2. Add only the project-board context (Status, Owner) and the high-level ask ("please propose how to address this").
3. **Strip everything else.** No "options I see", no "(a)/(b)/(c)" lists, no "trade-offs to consider", no "you may want to think about X". Even when the options seem helpful, leave them out.
4. The agent has the domain expertise to enumerate options on their own. That's their job, not yours.
5. If you genuinely don't understand the question well enough to relay it, ask lucas42 to clarify — don't paraphrase with your own framing.

Same applies to GitHub triage-decision comments on the ticket. Comments that say "Routing to the architect to decide between (a), (b), or (c)" plant the same bias as the SendMessage. Just say "Routing to the architect to propose an approach." See [[feedback-correct-agents]] for the two-message correction sequence when this slips through.