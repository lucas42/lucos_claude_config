---
name: Read the originating PR/issue body in full when writing incident-report causation
description: When writing an incident report, read the body of the PR/issue that triggered the incident. Don't reflex-frame the trigger as "routine" or "maintenance" without checking whether it was itself instructed by another piece of work — that under-states causation and reads as carelessness.
type: feedback
---

When an incident is triggered by an action (a deploy, a rotation, a config change, a credential update), the question "why was this action taken today, specifically?" is part of root-cause analysis, not background scenery. Before writing the incident-report Summary or Timeline, read the body of the PR/issue that drove the action and check whether the action was:

- **Discretionary maintenance** (genuinely routine — could have been done last week or next week, no external pressure) — fine to call "routine."
- **Instructed by another piece of work** (a PR body explicitly says "before merging, do X"; an issue says "as part of resolving this, run Y"; an ADR mandates a step) — this is *non-discretionary*. Calling it "routine" or "maintenance" is wrong, and it under-states the inevitability of the latent gap getting exposed.

The framing matters because it changes the report's "what would have prevented this" answer. If a rotation was discretionary, the answer is "do it less often" or "test it in dev first." If a rotation was instructed by a PR body, the answer is "the latent gap was bound to surface the moment anyone followed that PR's instructions" — which is a much sharper statement and points at a different fix shape.

**Why:** lucas42 corrected my draft of incident report PR lucas42/lucos#135 (2026-05-09) on exactly this. I'd written "A routine SSH key rotation for the `lucos-backups` user…" — but the rotation was actually performed as the documented post-merge step from `lucos_backups#265`'s body, which had said "easiest path is to run `rotate-ssh-key.sh` after merging" to clear a `~`-encoded production credential. The rotation was non-discretionary. Calling it "routine" both misrepresented the causation and weakened the report's "what would have prevented this" framing. I'd actually read PR #265's body earlier in the same session (when investigating the breakage) — the information was there, I just didn't carry it through to the incident-report writing pass.

**How to apply:** When drafting an incident report's Summary or Timeline, for any action that triggered the incident, **re-read the body of the originating PR/issue** even if you already read it during the investigation. Check specifically: does the PR body or issue description **instruct** the action that triggered the incident? If yes, frame the trigger as a documented step from that originating work, not as a discretionary maintenance task. Add the originating PR's body excerpt to the timeline as context if it's load-bearing. Only call something "routine" if you've actively confirmed there was no external instruction driving it.

**Memory aid:** "Don't say 'routine' without proving it." If the word "routine" or "maintenance" or "scheduled" makes it into your draft summary, treat that as a prompt to verify — go back to the originating work's body and check whether it explicitly directed the action. If it did, restructure the sentence.

Saved 2026-05-09 after the lucas42/lucos#135 flip-flop.
