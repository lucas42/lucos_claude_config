# Triage Reference Data

This file contains lookup tables and API patterns used during triage. It is re-read on demand (not injected into conversation history) to avoid context compression.

---

## Project Board IDs

The **lucOS Issue Prioritisation** project board: https://github.com/users/lucas42/projects/8

| Entity | ID |
|---|---|
| Project | `PVT_kwHOAAaLL84BRh5d` |
| **Status field** | `PVTSSF_lAHOAAaLL84BRh5dzg_VMcg` |
| **Priority field** | `PVTSSF_lAHOAAaLL84BRh5dzg_VMpk` |
| **Owner field** | `PVTSSF_lAHOAAaLL84BRh5dzg_VMvo` |

### Status options

| Option | ID | Legacy label equivalent |
|---|---|---|
| Ideation | `5f521008` | `needs-refining` + `status:ideation` — parked/vague, **no agent currently assigned**; agent-owed analysis goes to Needs Analysis instead. |
| Needs Analysis | `79f7273e` | (Renamed from "Needs Triage" on 2026-05-31; option ID unchanged.) The issue needs analysis/triage work — brand-new (auto-set on add) or routed to an agent. Surfaced on **every** triage pass **regardless of owner** so nothing strands; a persistent working column, **not** required to be empty after a pass. See the Status-field table in the coordinator persona for the per-pass decision (leave / nudge / transition). |
| Awaiting Decision | `cf5e250d` | `needs-refining` + `status:awaiting-decision` — **only for items where lucas42's personal input or decision is needed**. Do NOT use for issues awaiting agent design work. |
| Blocked | `d79b6b67` | `agent-approved` + `status:blocked` |
| Ready | `3aaf8e5e` | `agent-approved` (no blocking status); also where issues sit while being worked on |
| Done | `878c350f` | Set automatically when issue is closed |

### Priority options

| Option | ID | Legacy label equivalent |
|---|---|---|
| Critical | `546bd144` | `priority:critical` |
| High | `a3a12fdd` | `priority:high` |
| Medium | `f0df2978` | `priority:medium` |
| Low | `5f866d33` | `priority:low` |

### Owner options

| Option | ID | Legacy label equivalent |
|---|---|---|
| lucas42 | `f2527ea3` | `owner:lucas42` |
| lucos-developer | `cc3d3c3c` | `owner:lucos-developer` |
| lucos-architect | `59754dd6` | `owner:lucos-architect` |
| lucos-system-administrator | `0d03da01` | `owner:lucos-system-administrator` |
| lucos-site-reliability | `a64451c7` | `owner:lucos-site-reliability` |
| lucos-security | `a80e9bb6` | `owner:lucos-security` |
| lucos-issue-manager | `9e57855e` | `owner:lucos-issue-manager` |
| lucos-code-reviewer | `7ec5f738` | `owner:lucos-code-reviewer` |
| lucos-ux | `10276495` | `owner:lucos-ux` |

---

## Board API Patterns

Use `~/sandboxes/lucos_agent/gh-projects` (not `gh-as-agent`) for all project board API calls. This script authenticates with a PAT that has project access -- GitHub Apps cannot access v2 user projects.

### Complete workflow for a single issue

```bash
# 1. Get the issue's node ID
ISSUE_NODE_ID=$(~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager \
  repos/lucas42/{repo}/issues/{number} --jq '.node_id')

# 2. Add to project (idempotent — safe even if already on board)
ITEM_ID=$(~/sandboxes/lucos_agent/gh-projects graphql -f query='
mutation {
  addProjectV2ItemById(input: {projectId: "PVT_kwHOAAaLL84BRh5d", contentId: "ISSUE_NODE_ID"}) {
    item { id }
  }
}' --jq '.data.addProjectV2ItemById.item.id')

# 3. Set fields (Status, Priority, Owner — three separate calls using the item ID above)
~/sandboxes/lucos_agent/gh-projects graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwHOAAaLL84BRh5d"
    itemId: "PROJECT_ITEM_ID"
    fieldId: "FIELD_ID"
    value: {singleSelectOptionId: "OPTION_ID"}
  }) {
    projectV2Item { id }
  }
}'

# 4. Position by priority (omit afterId to move to top)
~/sandboxes/lucos_agent/gh-projects graphql -f query='
mutation {
  updateProjectV2ItemPosition(input: {
    projectId: "PVT_kwHOAAaLL84BRh5d"
    itemId: "PROJECT_ITEM_ID"
  }) {
    items(first: 1) { nodes { id } }
  }
}'
```

### Finding an issue's project item ID (for deletion or repositioning)

```bash
ITEM_ID=$(~/sandboxes/lucos_agent/gh-projects graphql -f query='
query {
  node(id: "ISSUE_NODE_ID") {
    ... on Issue {
      projectItems(first: 5) {
        nodes {
          id
          project { id }
        }
      }
    }
  }
}' --jq '.data.node.projectItems.nodes[] | select(.project.id == "PVT_kwHOAAaLL84BRh5d") | .id')
```

### Removing an item from the project board

```bash
~/sandboxes/lucos_agent/gh-projects graphql -f query='
mutation {
  deleteProjectV2Item(input: {
    projectId: "PVT_kwHOAAaLL84BRh5d"
    itemId: "PROJECT_ITEM_ID"
  }) {
    deletedItemId
  }
}'
```

### What the built-in workflows handle

- **Item added to project** -> sets Status to "Needs Analysis"
- **Item closed** -> sets Status to "Done"
- **Pull request merged** -> sets Status to "Done"

You **do** need to set the other fields (Owner, Priority) and either route the item to an agent (it stays in Needs Analysis, now owned) or transition it (Ready/Blocked/Awaiting Decision/Ideation) during triage. You do **not** need to set Status to "Done" when closing.

### Board sync rules

- **Every triage action MUST update the project board.** No exceptions.
- Always call `addProjectV2ItemById` first (idempotent safety net).
- Complete all four steps (add, set fields, position) as a single unit before moving to the next issue.
- **Always reposition items by priority, then by strategic tier within priority.** Critical/High: move to the correct position among same-priority items — strategic tier #1 work above tier #2 above no-tier (see `~/sandboxes/lucos/docs/priorities.md` for current tiers). Medium: place below the last High item, then ordered by strategic tier within Medium. Low: ordered by strategic tier within Low, bottom otherwise. Use `afterId` set to the item that should immediately precede yours, or omit `afterId` to move to the absolute top.
- **Always paginate board queries.** The board has 180+ items; use `pageInfo.hasNextPage` and cursors.
- **DANGER: `updateProjectV2Field` with `singleSelectOptions` regenerates ALL option IDs.** Avoid this mutation.

For label colours when **creating** new labels (e.g. `audit-finding`), see [`label-colours.md`](label-colours.md). Only the `audit-finding` label is still actively managed during triage — all other workflow state uses project board fields.
