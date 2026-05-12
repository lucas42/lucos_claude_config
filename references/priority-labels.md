# Priority Field

Set the **Priority field** on every issue during triage — not just issues with Status = Ready. This includes issues still being refined (Status = Ideation or Awaiting Decision). Early prioritisation helps lucas42 and agents understand which refinement work is most urgent.

Consult the **strategic priorities file** at `~/sandboxes/lucos/docs/priorities.md` to determine the correct priority level.

| Value | When to apply |
|---|---|
| High | High impact on users or other work; should be picked up soon. |
| Medium | Standard priority; pick up in normal queue order. |
| Low | Nice to have; only pick up when the queue is otherwise clear. |

Issues without a Priority field set have **not yet been prioritised** — this is distinct from Medium.

When picking up work, agents process issues in priority order: High first, then Medium, then Low. Within the same priority level, oldest issues first.

## Re-assessment after lucas42 input

When lucas42 gives input on an issue, re-assess the priority. Update the Priority field accordingly.

## Override rules

- **lucas42's priority calls override strategic priorities.** lucas42 is the repo owner and has final say.
- **Priority calls from others** (including other agents) should be considered within the context of the larger strategic priorities defined in `priorities.md`.

Read [`references/triage-reference-data.md`](triage-reference-data.md) for the Priority field ID and option IDs when setting via the GraphQL API.
