---
name: dont-publish-in-same-batch-as-evidence
description: Never put a publishing call (comment POST/PATCH, SendMessage with factual claims) in the same parallel tool block as the reads/fetches that establish its facts
metadata:
  type: feedback
---

Never issue a **publishing** action (a GitHub comment/issue/PR POST or PATCH, or a SendMessage carrying factual claims) in the **same parallel tool block** as the reads, greps, or API fetches that establish the facts that artifact asserts. Parallel calls run concurrently — the publish executes against your *assumptions*, before you've seen the read results.

**Why:** On lucos_monitoring#264 (2026-05-30) I batched a `cat > body.md` + comment POST together with the `Read loganne.erl` / `Read email.erl` calls. The POST ran before I'd processed the files, so the comment confidently asserted a fabricated `loganne send_event/3 that "ignores suppression entirely"` — invented from the ticket's framing, stated as "verified against origin/main". The real `loganne.erl` (`notify/1`→`buildEvent/5`) *is* suppression-aware. Had to PATCH a correction onto a fact-asserting comment lucas42 would otherwise read as ground truth. (A first, even-more-confabulated draft the turn before was saved only because a malformed command in the batch cancelled everything.) This is the [[feedback_read_the_pr_not_the_description]] / [[feedback_verify_before_propagating]] failure, but the specific *mechanism* is batching: the fix is sequencing, not just intent.

**How to apply:** Evidence-gathering and publishing go in **separate turns**. Gather (read/grep/fetch) → read the results → *then* compose and publish. It's fine to batch many independent reads together, and fine to batch independent publishes together — but a publish must never share a block with its own evidence. If you catch yourself writing a body file or SendMessage in the same block as a Read whose output that body depends on, split it. Also: never cite an ID/URL (comment id, issue number) you haven't seen in a tool result this turn — re-fetch or omit. ([[feedback_verify_past_tense_work_claims]], [[feedback_treat_empty_tool_output_as_unknown]])
