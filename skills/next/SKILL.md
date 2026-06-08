---
name: next
description: Implement the next issue
disable-model-invocation: true
---

Follow this process. Do not ask for clarification -- immediately begin Step 1.

## Ad-hoc dispatch

If the user gives a specific issue URL to implement (rather than asking for the next issue from the queue), skip Step 1 and go straight to Step 2 with that issue. In parallel with dispatching via `/dispatch` in Step 2, update the issue yourself: set it to `priority:high`, ensure it's on the project board, and move it to the top of the Ready column. Read `~/.claude/references/triage-reference-data.md` for field IDs and API patterns. If the user is explicitly asking for an issue to be picked up, it's clearly high priority to them.

### Triage untriaged issues as part of ad-hoc dispatch

**If an ad-hoc dispatched issue has never been triaged** (e.g. Status not yet set on the project board, Owner not set, Priority not set — often the case for issues raised moments before the user asks for them to be picked up), **do the triage inline as part of the dispatch** rather than refusing or waiting for a separate triage pass. Specifically:

1. Read the issue body and assess it against the normal triage criteria (clarity of outcome, clarity of approach, dependencies, architectural questions). If it is clearly specified and implementable, proceed. If not, stop and triage it through the normal refinement process instead — dispatching an un-implementable issue wastes the teammate's time.
2. Set Status = Ready, Priority = High (per ad-hoc rule above), and Owner = (appropriate persona) on the project board. If the user explicitly named an owner in their request, use that. Otherwise follow the normal implementation-assignment rules in `~/.claude/references/implementation-assignment.md`.
3. Add the issue to the project board if not already present, and position at the top of the Ready column. See `~/.claude/references/triage-reference-data.md` for field IDs and option IDs.
4. Then proceed with `/dispatch` as normal.

Rationale: ad-hoc dispatch implies the user wants the work done *now*, and the untriaged state is usually just "this was raised minutes ago and hasn't hit a triage pass yet." Blocking on triage would be friction without benefit. But do not dispatch an issue that is genuinely unclear or un-implementable just because the user asked — if it needs refinement, say so and refine it instead.

## Step 1: Find the next issue

Run the global prioritisation script:

```bash
~/sandboxes/lucos_agent/get-next-implementation-issue
```

This returns the next implementable issue from the **lucOS Issue Prioritisation** project board, choosing the topmost item in the Ready column whose Status is Ready (excluding Blocked) across all repositories and personas. **The ordering is determined by position in the Ready column, not by the Priority field value.** lucas42 may manually reorder the column to put a lower-priority issue ahead of a higher-priority one — that manual ordering is authoritative. **Do not second-guess what the script returns.** This means:

- Do not re-check the priority label and conclude the position must be wrong.
- Do not reason from recent conversation context (e.g. "lucas42 said this was for later, so the position must be a board default") — lucas42 routinely repositions things deliberately, including items he previously deferred, when capacity opens up.
- Do not assume a position is "default" or "accidental" just because you recently added the item to the board.
- Do not reframe a reposition as "fixing my own triage artifact" or "completing my positioning" — **even if you recently added the item and have a specific mechanistic story for why it's on top** (e.g. "items added via the project API default to the top, so this position is meaningless"). lucas42 routinely drags items to the top of Ready to prioritise them, so a top item is at least as likely his deliberate placement as your artifact. A top position you don't *remember him* setting is not evidence you set it.
- Do not reposition the item before dispatching — dispatch it. If the position is genuinely wrong, lucas42 will reposition it himself between turns; that's his call, not yours. **Never move a different item above what `/next` returned and dispatch that instead.** If you truly believe the order is wrong, dispatch what `/next` returned anyway, or ask lucas42 before changing the order — never silently override it.

The only valid reason not to dispatch what the script returns is a hard guardrail failure surfaced by `/dispatch` itself (open dependency, existing PR, estate-rollout detection). Anything else is second-guessing.

It prints three lines to stdout:

1. The owner in `owner:{name}` format (e.g. `owner:lucos-developer`) — sourced from the project board Owner field. Note: this is the script's output format, not a GitHub label. Strip the `owner:` prefix to get the teammate name for SendMessage.
2. The issue number and title (e.g. `#42 Fix the thing`)
3. The issue URL

It also writes `~/sandboxes/lucos_agent/.next-issue` (JSON with `url` and `owner` fields) — this is the hand-off file that Step 2 uses so the URL never has to be transcribed by the model.

If the script reports no implementable issues, tell the user there is nothing ready to implement right now and stop.

## Step 2: Dispatch the issue

Run `/dispatch` with **no URL argument**. The URL and owner are read automatically from the `~/sandboxes/lucos_agent/.next-issue` file written by Step 1. The model never transcribes the URL.

```
/dispatch
```

For ad-hoc dispatch (where the user gives you a URL directly), omit the owner and pass the URL as the argument — `/dispatch` will look up the owner from the project board.

The `/dispatch` skill handles all pre-dispatch validation (dependency checks, existing PR checks, convention/estate-rollout detection), dispatches to the correct teammate based on the owner, and handles post-completion (CI verification, auto-merge, unblocking dependents).

Wait for `/dispatch` to complete and report its outcome.
