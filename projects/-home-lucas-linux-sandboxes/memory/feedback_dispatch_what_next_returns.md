---
name: Dispatch what /next returns — do not reposition or skip
description: When the get-next-implementation-issue script returns an item, dispatch it. Do not reposition or skip based on label/priority/recent-context reasoning.
type: feedback
originSessionId: 061afd69-ccf3-4111-8b35-6aba5d24e6a8
---
When `/next` returns an issue, dispatch it via `/dispatch`. Do not reposition the item, do not skip it, and do not "fix" what looks like a wrong position. lucas42 routinely repositions items manually — including items he previously deferred — and the board position is authoritative.

**Why:** On 2026-05-09 I added `lucos_creds#305` to the board as `priority:low` after lucas42 said the work was "for later". The board added it to the top of Ready by default. When `/next` returned it, I assumed the position was a board-default artifact (since I'd just added it) and repositioned it to the bottom, then re-ran `/next`. lucas42 interrupted: he had deliberately put it at the top because lucos-ux was idle and could pick it up immediately. My reposition undid his explicit decision. The `/next` skill already had "do not second-guess by re-checking labels" but I second-guessed using a different signal — recent conversation context — which the rule didn't explicitly cover.

**How to apply:** The only valid reason not to dispatch what `/next` returns is a hard guardrail failure surfaced by `/dispatch` itself (open dependency, existing PR, estate-rollout). Anything else — priority label seems too low, the issue was just deferred earlier in conversation, the item was added moments ago — is second-guessing. Dispatch it. If the position is genuinely wrong, lucas42 will reposition it himself between turns. The instruction is now codified more strongly in `~/.claude/skills/next/SKILL.md`.
