---
name: submission-memory-sweep
description: When Luke says an application is submitted, batch ALL durable memory updates at that point alongside the notes.md update — not at end of session.
metadata:
  type: feedback
---

When Luke says he's submitted an application (e.g. "I've submitted the Freetrade application"), the right response is to batch **all** durable memory updates from the session at that point, in the same turn as the notes.md submission-status update — not to wait for an end-of-session prompt.

**Why:** Stated 2026-05-21 after the Freetrade session. I updated `notes.md` to record the submission, then waited until Luke asked at session-end to capture the durable lessons in memory. That meant two passes when one would do; Luke shouldn't have to prompt me to do the sweep. The submission moment is the natural reflection point — the application is locked in, the consultation is over, all the framings + voice rules + gotchas surfaced during the work are stable enough to commit to memory.

**How to apply:**

When Luke reports a submission, in the same turn:

1. Update `orgs/{company-slug}/notes.md` with the submission status / date.
2. Sweep the session for durable lessons worth banking:
   - Did Luke confirm a new defensible skill / tech / methodology? → append to `user_skills_inventory.md`
   - Did Luke surface a new framing rule, level-positioning insight, or absorption-style narrative? → append to `user_role_framing.md`
   - Did Luke flag a banned word, voice rule, or tone preference? → append to `feedback_luke_voice.md`
   - Did Luke correct a workflow / process? → new `feedback_*.md` memory
   - Did Luke point out a tool / pipeline gotcha? → new `feedback_*.md` memory
   - Did the consultation surface a new evidence-story shape, opener pattern, or current-focus variant? → propose for the `cover-letters/blocks/` library
   - Did the consultation deploy a new framing for the first time? → update the relevant `project_*.md` to log it
3. Update `MEMORY.md` index for any new memory files.
4. Commit + push the memory changes (and any library / cv-extended.md propagations) **before** considering the submission complete.

**What this changes vs. the existing `/tailor` skill flow:** the Step 12 "upstream propagation" already calls for default-saving memory changes during the per-application work. This rule just makes it explicit that the *final sweep* happens at submission time, not at session-end. If memory was default-saved during the consultation it's already done; what remains at submission is the lessons that only crystallised in retrospect (recency-objection pattern, tool gotchas, the meta-lesson "this consultation deployed a new framing for the first time").

**Quick mental checklist** to run at submission:

- New skill / tech defensibility confirmed?
- New framing rule or absorption-bridge pattern?
- New banned word or voice nuance?
- New tool / pipeline gotcha?
- First-time deployment of an existing framing pattern (worth logging in `project_*.md`)?
- Any library-block (`cover-letters/blocks/`) additions or refinements?

If yes to any: capture before reporting "done".

Related: [[cv-commit-discipline]], [[cover-letter-rebuild]].
