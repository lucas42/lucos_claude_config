---
name: Always re-fetch comments AND reactions on actively discussed issues
description: During triage, re-fetch comments and check reactions on any issue that was under active discussion — lucas42 may approve via +1 reaction
type: feedback
---

Two related patterns to guard against:

### 1. Re-read ALL comments AND check reactions after agent consultation

After sending an agent to post a comment on an issue, always re-read ALL comments AND check reactions when assessing the result. lucas42 may have replied in text or added a +1 reaction to the agent's comment. A +1 reaction counts as approval per the "Reactions as approval" instruction.

### 2. Re-fetch comments and reactions on "no change" issues during subsequent triage passes

When a triage pass includes issues that were already triaged earlier in the same session, do NOT rely on what was last seen. Re-fetch comments and check reactions before reporting "no change."

**Why:** These mistakes happened multiple times in one session (2026-03-19):
- lucos_photos_android#80: lucas42 approved via text at 11:42, missed during re-read after architect posted at 11:37
- lucos_monitoring#74: lucas42 approved Option 3 via text at 14:03, missed during next triage pass
- lucos_repos#159: lucas42 approved via +1 reaction on the architect's revised design comment, missed because reactions weren't checked during re-read

**How to apply:** For every issue re-read (whether after consultation or during a subsequent triage pass), always fetch comments with reactions data and check for +1 reactions from lucas42 on every comment — especially the most recent agent comment. The existing "Reactions as approval" instruction already defines the semantics; the gap was not applying it during re-reads.
