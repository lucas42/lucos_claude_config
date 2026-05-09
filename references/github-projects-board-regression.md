# GitHub Projects v2 Board — Status Field / Column Position Regression

**Investigated:** 2026-04-21  
**Status:** Suspected GitHub regression — no action taken, monitoring

---

## What we observed

The lucOS Issue Prioritisation board (project 8, `PVT_kwHOAAaLL84BRh5d`) had multiple issues appearing in the wrong columns:

- Issues in the **"Needs Triage"** column with Status field = "Ready"
- Closed issues in the **"Ready"** column with Status field = "Done" (or Status = "Ready" despite being closed)
- Issues in a **"No Status"** column despite Status field being set to "Ready"

## Root cause (as understood)

GitHub Projects v2 tracks two separate things:

1. **Card column position** — the internal position that determines which column the card is rendered in on the board
2. **Status field value** — the single-select field value shown as metadata on the card

These are *meant* to stay in sync but can diverge. Investigation confirmed:

| Action | Status field | Card column |
|---|---|---|
| `addProjectV2ItemById` + immediate `updateProjectV2ItemFieldValue` | ✅ updates | ✅ initialised from field (once, at creation) |
| Subsequent `updateProjectV2ItemFieldValue` via API | ✅ updates | ❌ stays put |
| Editing Status field via UI field editor | ✅ updates | ❌ stays put |
| Dragging card to different column in UI | ✅ updates | ✅ moves |
| GitHub built-in automation (e.g. issue closed → Done) | ✅ updates | ✅ moves |

**The public `updateProjectV2ItemFieldValue` mutation only updates the field value, not the card's column position.** GitHub's internal automation code path updates both.

## Why this matters

The triage workflow calls `updateProjectV2ItemFieldValue` for Status when triaging issues (setting Ready, Ideation, etc.). This correctly updates the Status field but does *not* move the card to the corresponding column. The board then shows stale column positions that diverge from the field values.

## Board configuration (confirmed on both old and new boards)

Both the existing board and a freshly created test board have identical view configuration:

```
layout: BOARD_LAYOUT
groupByFields: []          ← empty
verticalGroupByFields: Status
filter: -status:Done
```

This is GitHub's default board configuration — there is no misconfiguration on the old board.

## Workarounds used

1. **Delete + re-add**: `deleteProjectV2Item` then `addProjectV2ItemById` + `updateProjectV2ItemFieldValue`. Works because column position is initialised correctly from Status field on fresh item creation. Used for the `lucos_deploy_orb#144` case.

2. **Reopen + close cycle**: For issues that need to land in Done, reopen the GitHub issue and close it again. Triggers the built-in automation which correctly updates both field and column. Used for `lucos_arachne#388`, `#389`, `#391`.

## Specific incidents cleaned up during investigation

- **lucos_arachne #388, #389, #391** — closed issues stuck in Ready column (Status=Ready). Fixed via reopen/close cycle.
- **lucos_deploy_orb #144** — open issue in "No Status" column (Status=Ready). Fixed via delete+re-add.
- **3 issues in "Needs Triage" column** — had Status=Ready. Resolved themselves when the board was queried (GitHub lazy reconciliation).

## Why this is probably a GitHub regression

lucas42 confirmed this behaviour was not always the case — the board previously moved cards correctly when the Status field was changed. Neither the board configuration nor the agent triage workflow changed. A fresh test board created on 2026-04-21 exhibited identical behaviour. This points to a change on GitHub's side.

**Decision:** No workflow changes made. Monitor to see if GitHub fixes it. If the problem persists, the fix would be to replace `updateProjectV2ItemFieldValue` for Status with delete+re-add on every Status change in the triage workflow.
