---
name: Always re-fetch comments on actively discussed issues before reporting
description: During triage, re-fetch comments on any issue that was under active discussion this session before reporting it as unchanged
type: feedback
---

Two related patterns to guard against:

### 1. Re-read ALL comments after agent consultation

After sending an agent to post a comment on an issue, always re-read ALL comments when assessing the result — not just the agent's comment. lucas42 may have replied in the minutes between the agent posting and the issue manager re-reading.

### 2. Re-fetch comments on "no change" issues during subsequent triage passes

When a triage pass includes issues that were already triaged earlier in the same session, do NOT rely on what was last seen. Re-fetch comments before reporting "no change." lucas42 may have responded between triage passes.

**Why:** This mistake happened three times in one session (2026-03-19):
- lucos_photos_android#80: lucas42 approved at 11:42, missed during re-read after architect posted at 11:37
- lucos_monitoring#74: lucas42 approved Option 3 at 14:03, missed during next triage pass
- lucos_repos#159: lucas42 gave clear direction at 13:42, architect posted revised design at 14:11, both missed

**How to apply:** For every issue in a triage batch that was discussed earlier in the session, always fetch the latest comments and check if lucas42 (or any user) has responded since you last looked. Do this even if the issue appears in the triage script output with the same labels as before. The labels haven't changed because YOU haven't changed them yet — but the conversation may have moved on.
