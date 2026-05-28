---
name: refetch-state-before-writing-final-artifact
description: Before writing a multi-ticket status summary, end-state footer, or "where things stand" recap, re-fetch each ticket's live state from GitHub rather than asserting from conversational memory
metadata:
  type: feedback
---

# Re-fetch state before writing it into a final artifact

**Rule:** When composing a status summary, end-state footer, or "where things stand" recap that asserts the state of multiple tickets / PRs / branches, **re-fetch each one's live state from the durable source of truth** before writing. Don't compose the summary from conversational memory of "when I last saw it".

**Why:** This failed on 2026-05-28 in two ways within hours of each other:

- **SRE on `lucos#199`** (saved in their `feedback_refetch_state_before_writing_final_artifact.md`).
- **Architect on `lucos_claude_config#97`**: I wrote "still sole canonical home for the rule" and "open, awaiting implementer" in two consecutive summary footers to team-lead after `lucos_repos#404` was closed. #97 had actually closed at 19:23:44Z (via PR #100's `Closes #97` keyword) before either footer was written — but I'd last engaged with #97 when it was open and didn't re-fetch before asserting.

The failure mode is silent: the assertion reads as a confident summary of work done, the recipient takes it as accurate, and the stale state propagates downstream until someone re-fetches and notices.

**How to apply:**

- The trigger pattern is "I'm about to write a list of N tickets and their current states". When you catch yourself doing that, treat it as a re-fetch obligation. `gh-as-agent ... /issues/{N} --jq '.state, .state_reason'` per ticket. Cheap.
- Especially fire on words like "still open", "still closed", "still awaiting", "open / awaiting implementer", "merged", "in flight" — these read as live-state assertions and need to be live.
- The existing canonical rule in [`references/teammate-communication.md`](../../references/teammate-communication.md) § "Cross-check substantive claims from teammates" covers this in principle ("trust verifiable sources over secondary channels, even when the secondary channel is your own inbox") — but its framing is teammate-claim-anchored and doesn't fire on "writing a summary footer". This memory is the persona-local pointer that bridges the gap.
- The opposite of this rule is also useful: if a teammate sends you a multi-ticket summary, treat each line as a prediction until you've verified it. Same principle, different actor.

**Why a memory and not a shared-reference edit:** I considered tightening the canonical rule in `teammate-communication.md` to explicitly cover the summary-footer case, but after the `d0874bc` retraction earlier today (where I reached for a shared-reference consolidation that turned out unwarranted), I'm being more conservative about reaching for shared-reference edits without a clearer mandate. Persona-local memory is the right scope for now. If the same failure recurs across multiple personas in similar shapes, that's the trigger to push for a canonical-reference tightening.

Related: [[feedback_verify_past_tense_work_claims]] — same family (verify before asserting), different surface (teammate claims vs. your own composed summary).
