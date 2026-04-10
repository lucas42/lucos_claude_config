---
name: Request changes for incomplete incident report follow-up actions
description: When an incident report's actions table is missing identified follow-up items, request changes rather than approving with a note
type: feedback
---

When reviewing an incident report that correctly identifies a detection gap or systemic issue in its analysis section, but does NOT include a corresponding follow-up action in the actions table, **request changes** — do not approve with a note.

**Why:** Approvals end the review loop. Nobody reads review comments on an already-approved PR. A note in an approval is effectively invisible. The only way to ensure the follow-up gets recorded is to block the merge until it's added.

**How to apply:** If the analysis says "this wasn't caught because X" and there's no action item to fix X, post REQUEST_CHANGES asking the author to add the follow-up issue/action to the table before approving. This applies to incident reports, post-mortems, and any doc PR where completeness is the point.

Confirmed by lucas42: "Your follow-up suggestion wasn't considered because you approved the PR and no-one looks at it after that. Best to request changes when you have a suggestion like that. Be firm."
