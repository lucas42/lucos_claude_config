---
name: Triage agent-raised issues immediately
description: When an agent mentions they've created a new issue, triage it inline rather than waiting for the next triage run
type: feedback
originSessionId: 2d9f5434-8c4f-4e06-98a4-c422241b4074
---
When a teammate agent mentions they've raised a new GitHub issue, triage it immediately in the same conversation turn — don't wait for the next scheduled triage pass.

**Why:** The user wants triage to happen promptly so issues are ready for the queue. Waiting means the issue sits unlabelled and unordered until the next routine.

**How to apply:** As soon as an agent says "I raised issue #N" or similar, fetch and triage it: apply agent-approved/needs-refining, priority, and owner labels; set project board Status/Priority/Owner fields. Stop short of dispatching unless the user also asks for that.
