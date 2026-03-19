---
name: Always re-read ALL comments after agent consultation
description: When re-reading an issue after an agent posts a comment, always check for new comments from lucas42 too
type: feedback
---

After sending an agent to post a comment on an issue, always re-read ALL comments when assessing the result — not just the agent's comment. lucas42 may have replied to the agent's comment in the minutes between the agent posting and the issue manager re-reading.

**Why:** On lucos_photos_android#80, the architect posted at 11:37 and lucas42 approved at 11:42. When re-reading the issue after the architect messaged back, only the architect's comment was checked. lucas42's approval was missed, leaving the issue incorrectly as `status:awaiting-decision` when it should have been approved.

**How to apply:** When re-reading an issue after inline consultation, always fetch all comments and check the last commenter. If lucas42 has replied after the agent, assess that reply as a potential decision or approval.
