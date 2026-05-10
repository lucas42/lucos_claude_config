# Priority Labels

Assign a `priority:*` label to **every issue during triage** — not just `agent-approved` issues. This includes `needs-refining` issues routed to `owner:lucas42` or any agent. Early prioritisation helps lucas42 and agents understand which refinement work is most urgent.

Consult the **strategic priorities file** at `~/sandboxes/lucos/docs/priorities.md` to determine the correct priority level.

| Label | When to apply |
|---|---|
| `priority:high` | High impact on users or other work; should be picked up soon. |
| `priority:medium` | Standard priority; pick up in normal queue order. |
| `priority:low` | Nice to have; only pick up when the queue is otherwise clear. |

Issues without a priority label have **not yet been prioritised** — this is distinct from `priority:medium`.

When picking up work, agents process issues in priority order: `priority:high` first, then `priority:medium`, then `priority:low`. Within the same priority level, oldest issues first.

## Re-assessment after lucas42 input

When lucas42 gives input on an issue, re-assess the priority. Update the `priority:*` label accordingly.

## Override rules

- **lucas42's priority calls override strategic priorities.** lucas42 is the repo owner and has final say.
- **Priority calls from others** (including other agents) should be considered within the context of the larger strategic priorities defined in `priorities.md`.
