---
name: askuserquestion-phrasing
description: Phrase AskUserQuestion options with clear "tick to approve" semantics; never use ambiguous "any objections" or "select to flag" framings with multi-select
metadata:
  type: feedback
---

When using `AskUserQuestion` (especially with `multiSelect: true`), the question prompt and option labels must use unambiguous **select-to-approve** semantics.  The reader must be able to tell, at a glance, whether ticking a box means "approve" or "object".

**Bad** (ambiguous):

> "I've surfaced four durable rules I'd like to save. Confirm any objections."
> [multi-select: tick-each-rule]

The user can't tell whether ticking a rule means "save it" or "flag it as objectionable" — the question prompt says "confirm objections" (objection-flagging) but the options are the rules themselves (approval-listing).  Stated 2026-05-26 after Luke called this out: "Your framing of the question is odd — not sure if you want me to select the rules to save to memory, or any I object to."

**Good** (clear select-to-approve):

> "Which of these four rules should I save to memory?  Tick each one you want saved."
> [multi-select: tick-each-rule]

Or, if a single approve-the-batch question fits better:

> "Save these four rules to memory?  Yes / No"
> [single-select, no multi]

**Why**: multi-select questions with ambiguous polarity make the user spend cognitive cost on parsing what the tick means before they can answer.  That's exactly the friction `AskUserQuestion` is meant to reduce.

**Rule**:
- Question prompt names the **action that ticking performs** ("Which to save?", "Which to apply?", "Select the ones to include").
- Never use "object" / "flag" / "veto" polarity with multi-select — those constructions read naturally as "tick to object" but I've found myself drifting into them when listing things-to-approve.
- If the only natural framing is objection-based ("which of these is wrong?"), use single-select with a follow-up free-text rather than multi-select.

**How to apply**: before issuing any `AskUserQuestion` with `multiSelect: true`, re-read the question prompt and ask: "if a user ticks this option, what do they mean?"  If the answer isn't obvious in one second, rewrite to lead with the action verb ("Save…", "Apply…", "Include…").

Related: [[ambiguous-user-reply]], [[no-options-in-consultations]].
