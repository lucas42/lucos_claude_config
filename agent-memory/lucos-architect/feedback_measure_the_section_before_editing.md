---
name: measure-the-section-before-editing
description: Standing instruction — before editing any section of agents/lucos-architect.md, measure it; if it has grown against where you started, cut something. Watch relocations that quietly grow.
metadata:
  type: feedback
---

Before editing `agents/lucos-architect.md`, measure **the section you are about to edit** (this was originally scoped to Self-Verification alone — too narrow; see the 2026-08-30 instance below). At the end of the edit, measure it again *against the state you started from* — not against one item, and not against an intermediate commit. If it has grown, find something to cut before committing.

**Why:** 2026-08-18, coordinator's standing observation. Across three commits in one evening the section went 17,053 → 17,308 → 17,482 (**+429**; the coordinator measured +431 on a slightly different boundary — the agreement between two independent boundary definitions is what makes the figure trustworthy). Every increment was individually defensible and two were explicitly approved, yet the evening's stated theme was *consolidation*. The reason it matters is already in the file: long persona files cause attention degradation, so rules buried deep stop firing — which is the failure mode that produced that evening's original miss. **Net growth under a consolidation banner is the thing to watch precisely because each step looks like tightening.**

**How to apply:** any edit to that file. Measure the section, not a line — see [[commit-the-tools-own-serialisation]]'s sibling lesson in Self-Verification item 4: the quantity you cite must measure the thing you are claiming about. Do not over-correct by cutting load-bearing detail to hit a number; if an addition genuinely earns its size, say so and cut elsewhere, or say plainly that the section grew and why.

**Second instance, 2026-08-30 — the reflex survives being named.** Having broken the never-backtick-a-reference rule that was *already in this file in my own words*, my first move was to restate it more loudly in the same file: a ~15-word parenthetical became a full paragraph, which I described to myself and to the coordinator as a **relocation** and a consolidation. It was reverted. Two things to carry:

- **The tell is a "move" whose net line count goes up.** A genuine relocation is cut-and-paste; if the text grows on the way, it is an addition wearing a move's clothing. Diff the before/after word counts of what you claim to be moving.
- **This memory did not fire, because it named one section and I was editing another** — the identical failure mode I had just diagnosed in the backtick rule (a correct rule sitting in a room you don't enter for this task). Hence the broadened scope above. A rule scoped to where you last got it wrong will not catch you where you get it wrong next.

Related: [[shared-claude-checkout-ref-state]].
