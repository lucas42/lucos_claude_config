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

| Option | ID | Maps to |
|---|---|---|
| Ideation | `5f521008` | `needs-refining` + `status:ideation` |
| Needs Triage | `79f7273e` | No labels yet (set automatically when item is added) |
| Awaiting Decision | `cf5e250d` | `needs-refining` + `status:awaiting-decision` |
| Blocked | `d79b6b67` | `agent-approved` + `status:blocked` |
| Ready | `3aaf8e5e` | `agent-approved` (no blocking status); also where issues sit while being worked on |
| Done | `878c350f` | Set automatically when issue is closed |

### Priority options

| Option | ID | Maps to |
|---|---|---|
| Critical | `546bd144` | `priority:critical` |
| High | `a3a12fdd` | `priority:high` |
| Medium | `f0df2978` | `priority:medium` |
| Low | `5f866d33` | `priority:low` |

### Owner options

| Option | ID | Maps to |
|---|---|---|
| lucas42 | `a9a6994c` | `owner:lucas42` |
| lucos-developer | `a9aa2c31` | `owner:lucos-developer` |
| lucos-architect | `6dd9da80` | `owner:lucos-architect` |
| lucos-system-administrator | `29bb2d74` | `owner:lucos-system-administrator` |
| lucos-site-reliability | `342f9448` | `owner:lucos-site-reliability` |
| lucos-security | `2adf0456` | `owner:lucos-security` |
| lucos-issue-manager | `be20910b` | `owner:lucos-issue-manager` |
| lucos-code-reviewer | `89bbc325` | `owner:lucos-code-reviewer` |

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

- **Item added to project** -> sets Status to "Needs Triage"
- **Item closed** -> sets Status to "Done"
- **Pull request merged** -> sets Status to "Done"

You **do** need to set status to the correct value immediately after adding (since your triage action moves it past "Needs Triage"). You do **not** need to set Status to "Done" when closing.

### Board sync rules

- **Every triage action that changes labels MUST also update the project board.** No exceptions.
- Always call `addProjectV2ItemById` first (idempotent safety net).
- Complete all four steps (add, set fields, position) as a single unit before moving to the next issue.
- **Always reposition items by priority.** Critical/High: move to top (no `afterId`). Medium: place after the last High item (or move to top if unknown). Low: leave at bottom.
- **Always paginate board queries.** The board has 180+ items; use `pageInfo.hasNextPage` and cursors.
- **DANGER: `updateProjectV2Field` with `singleSelectOptions` regenerates ALL option IDs.** Avoid this mutation.

---

## Label Colour Scheme

When creating labels, always set the colour explicitly. GitHub's default is `ededed` (grey).

### Agent workflow labels

| Label | Colour |
|---|---|
| `agent-approved` | `0e8a16` (green) |
| `needs-refining` | `d93f0b` (orange) |

### Status labels

| Label | Colour |
|---|---|
| `status:ideation` | `c5def5` (light blue) |
| `status:needs-design` | `fbca04` (yellow) |
| `status:awaiting-decision` | `b60205` (red) |
| `status:blocked` | `1d76db` (blue) |

### Owner labels

| Label | Colour |
|---|---|
| `owner:lucas42` | `e4e669` (light olive) |
| `owner:lucos-architect` | `d4c5f9` (light purple) |
| `owner:lucos-system-administrator` | `bfdadc` (light teal) |
| `owner:lucos-site-reliability` | `fef2c0` (cream) |
| `owner:lucos-security` | `f9d0c4` (light pink) |
| `owner:lucos-developer` | `c2e0c6` (light green) |

### Priority labels

| Label | Colour |
|---|---|
| `priority:critical` | `e11d48` (dark red) |
| `priority:high` | `b60205` (red) |
| `priority:medium` | `fbca04` (yellow) |
| `priority:low` | `c5def5` (light blue) |
