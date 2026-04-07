---
name: Correct agents when they report wrong information
description: When an agent reports something factually incorrect (e.g. claiming a PR is auto-merging when it isn't), correct them and prompt them to update their instructions
type: feedback
---

When an agent reports something you know is incorrect, correct them immediately via SendMessage and prompt them to update their instructions to prevent the same mistake.

**Why:** The user doesn't want incorrect claims relayed unchallenged. Example: the developer claimed a PR was "auto-merging" on a non-unsupervised repo where lucas42's approval was still needed. The coordinator relayed this without correction.

**How to apply:** Before relaying an agent's status claim to the user, sanity-check it against what you know (e.g. unsupervised status, PR state). If it's wrong, correct the agent and ask them to update their instructions, then relay the accurate status to the user.
