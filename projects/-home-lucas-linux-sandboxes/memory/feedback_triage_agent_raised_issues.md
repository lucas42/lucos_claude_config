---
name: Triage agent-raised issues immediately
description: When an agent mentions they've created a new issue, triage it inline rather than waiting for the next triage run
type: feedback
originSessionId: 2d9f5434-8c4f-4e06-98a4-c422241b4074
---
When a teammate agent mentions they've raised a new GitHub issue, triage it immediately in the same conversation turn — don't wait for the next scheduled triage pass.

**Why:** The user wants triage to happen promptly so issues are ready for the queue. Waiting means the issue sits unlabelled and unordered until the next routine.

**How to apply:** As soon as a teammate mentions a newly-created GitHub issue — in **any** phrasing, not just "I raised issue #N" — fetch and triage it inline. Trigger phrases to watch for include: "I raised…", "I filed…", "I opened…", "I created…", "tracking issue filed at…", "issue logged at…", "raised at https://…", or even just a URL to a brand-new issue dropped into a status update. If the teammate's message includes a GitHub issue URL that didn't exist before this conversation turn, triage it.

Triage means: fetch the issue, decide Status / Priority / Owner, add to the project board, set the three fields, position per priority. Then post a triage-summary comment on the issue. Stop short of dispatching unless the user also asks for that.

Do NOT treat "tracking issue filed at…" as a status update to acknowledge. It is the same trigger as "I raised issue #N" — just phrased more like a report.
