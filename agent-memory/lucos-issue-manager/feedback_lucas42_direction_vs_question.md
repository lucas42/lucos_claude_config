---
name: lucas42 rejecting + describing alternative = approved direction
description: When lucas42 rejects an approach and describes a concrete alternative, treat the alternative as the approved direction — don't route back for re-approval
type: feedback
---

When lucas42 rejects a proposed approach and describes a concrete alternative with specifics, treat the alternative as the approved direction. The architect's role is to flesh out implementation details, not to propose something fundamentally different that needs re-approval.

**Why:** On lucos_repos#159, lucas42 rejected the per-convention cap and described what he wanted instead: "run a dry-run as part of the pull request process, post the diff between that and the latest production audit run." This was treated as an open question needing more design, when it was actually lucas42 describing what he wanted built. The architect's revised design implemented lucas42's direction, but the issue was incorrectly left as `status:awaiting-decision` + `owner:lucas42` — routing it back to lucas42 to approve his own idea.

**How to apply:** After lucas42 rejects approach A and describes approach B with concrete details (specific mechanism, integration points, what the output should look like), treat B as the approved direction. Send the architect to flesh out implementation details, then approve the issue once the architect posts. Only route back to `owner:lucas42` if the architect's design departs significantly from what lucas42 described, or if genuinely new open questions emerge that lucas42 didn't address.
