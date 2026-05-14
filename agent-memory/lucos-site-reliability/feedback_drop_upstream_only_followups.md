---
name: drop-upstream-only-followups
description: Don't pursue upstream-only Claude Code follow-ups; capture architectural principles on the bespoke-harness ideation ticket instead
metadata:
  type: feedback
---

When a proposed follow-up from an incident or investigation is **specific to Claude Code's implementation** — i.e. fixable only by Anthropic shipping a change, with no self-actionable workaround — **drop it**. Don't file an issue on `anthropics/claude-code`; don't comment on existing ones either; don't spend drafting time on a structured reproduction.

**Why:** lucas42's explicit rule on 2026-05-14: *"Anthropic have proven themselves rubbish at responding to user-generated bug reports. If there's anything architectural that'll need consideration in a future harness, you can add a note to lucos#155. But if it's specific to claude code's implementation, let's drop it."* Anthropic's response cadence on user-filed bugs on that repo doesn't justify our drafting time.

**How to apply:**

- For each proposed follow-up, ask: *(a) is this self-actionable (config / hooks / MCP / scripts / persona rules) or (b) upstream-only?*
- If (a): proceed normally — scope a ticket, file via the right persona, ship.
- If (b): assess whether the underlying *architectural principle* is relevant to a future bespoke harness (see [`lucas42/lucos#155`](https://github.com/lucas42/lucos/issues/155)).
  - If yes — **add a comment to lucos#155** capturing the principle (not the specific Claude Code implementation detail). One paragraph max, framed as "consideration for the future-harness design space" rather than as a current actionable change.
  - If no — drop it entirely. No comment, no ticket, no thread.
- Either way, if the proposal is referenced in any open follow-up artifact (e.g. an incident report's Follow-up Actions table), mark the row **Not Pursued** with the upstream-only reasoning, so the artifact stays accurate.

**Related discipline:** the architect's self-actionability triage (Stage 7-era) and lucas42's earlier upstream-drop on `anthropics/claude-code#44778` are precursors to this generalised rule. Treat them as the same posture.
