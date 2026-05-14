---
name: feedback-refetch-issue-comments-before-following-up
description: "Before posting a substantive follow-up comment on a GitHub issue — even one I filed myself only minutes ago — re-fetch comments so I don't stomp on intervening updates."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: dcd1a08d-146c-4467-9166-65efa2316723
---

Before posting any substantive follow-up comment on a GitHub issue (e.g. a progress update, a triage decision, a "1 of N done"-style status note), re-fetch the issue's comments immediately before drafting. This applies even when I filed the issue myself only minutes earlier — others (especially lucas42) may have commented in that gap and my follow-up may either contradict their update or render it invisible.

**Why:** On 2026-05-14 I filed `lucos_creds#321` to track 12 production cred updates. ~10 minutes later lucas42 commented on it saying he had *already* done all 12 cred updates and that redeploys would happen as each migration PR landed. I didn't re-fetch the comments before posting my own "Progress update: 1 of 12 done" comment 9 minutes after his — I assumed the only context on the issue was my own filing. The result: I spent the next several hours wrongly relaying "cred updates still pending" to lucas42 each time a migration merged, until he had to explicitly tell me he'd already done the work and had commented about it.

**How to apply:** Whenever I'm about to post a `comments` POST on a GitHub issue, the last action immediately before drafting the body must be a fresh `gh-as-agent ... /comments` fetch on that issue. If the latest comment is from lucas42 (or any other party I wasn't expecting), read it in full before drafting and incorporate it. This is a strict generalisation of [[feedback-refetch-before-accusing]] — the rule there is about claims against other agents' state; this rule is about avoiding stomping on the issue's own state.

A simpler heuristic that catches this case: **never compose a "progress update" comment without first reading the comments that have arrived since I last looked at the issue**, including comments that arrived between filing and following up.
