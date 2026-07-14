---
name: pull-architect-on-schema-scope-changes
description: When lucas42 revises scope on a converged design and the change touches a data-model justification the architect made, re-consult the architect rather than deciding the schema consequence myself
metadata:
  type: feedback
---

When a scope change looks like a small UI subtraction ("drop this one flag reason") but the design's schema shape was justified by exactly that requirement, don't quietly shrink the schema myself — go back to whoever made the original data-model call.

**Why:** On lucos_photos#471, lucas42 offered to drop the "wrong profile picture" flag reason "if it's adding schema complexity." It looked like a clean subtraction from the UX side. But lucos-architect's original design had justified the `person_flag` table + `reason_code` enum partly on that exact reason ("has no other home"). Re-consulting the architect surfaced that their own justification was internally inconsistent (they'd said in the same comment that the ML signal was the confirmed-`Face` corpus, not the flag — which undercut the table's own history argument), and the true fix for "wrong profile picture" was a different, half-built feature entirely (see [[lucos_photos_person_flag_pattern]]). The result was a materially smaller design (one nullable column instead of a table+enum) that I would not have arrived at by just editing the enum's list of values.

**How to apply:** Any time a scope change from lucas42 or triage lands on a data-model decision that wasn't originally mine, re-open it with the architect explicitly — even if the requested change reads as "just remove this one option." Ask the specific question ("does the schema still earn its place without X?") rather than assuming the answer and rewriting the issue body myself. This is also team-lead's standing expectation per [[feedback_fyi_not_dispatch]]-adjacent triage routing: schema consequences of scope changes are pulled in inline, not absorbed silently.
