---
name: feedback-review-event-must-match-body
description: When a review body says "I'm withholding approval" for an operational reason (merge-order, sequencing), the -f event= parameter must be COMMENT, not APPROVE — the API call is the source of truth, not the prose
metadata:
  type: feedback
---

On `lucos_worlds#68` (2026-08-06) I wrote a review body stating "I'll hold my approval on this PR until #67 has actually merged" to avoid a merge-order race — then submitted the same call with `-f event="APPROVE"`, directly contradicting the sentence I'd just written. On this unsupervised repo my APPROVE *is* the auto-merge trigger, so the mistake recreated exactly the race the body was warning about. Caught it immediately after the tool call returned and confirmed `state: "APPROVED"` in the response — dismissed the review via `PUT .../reviews/{id}/dismissals` with an explanit correction message, then re-posted the same assessment as a `COMMENT` review.

**Why:** when drafting a review body with any sentence about withholding, delaying, or conditioning approval, the `-f event=` value in the same tool call needs to be re-checked against that sentence before sending — not assumed to already match a mental model of "this is basically an approval." GitHub's review state is exactly what the `event` parameter says, irrespective of what the body text claims. A contradiction between the two is not a wording nitpick — on any repo where bot approval is the merge trigger, it's a live operational hazard.

**How to apply:** before calling the reviews API, read back the drafted body for any hedge/hold/wait language ("I'll approve once X", "holding on Y", "not yet"). If present, the event MUST be `COMMENT`, never `APPROVE` — there is no such thing as a conditional or partial APPROVE at the API level. If an APPROVE is mistakenly submitted, `PUT /repos/{owner}/{repo}/pulls/{pr}/reviews/{review_id}/dismissals` (body: `{"message": "...", "event": "DISMISS"}`) cleanly withdraws it — check whether any auto-merge workflow run fired in the interim (`actions/runs?per_page=5`) before assuming the dismissal fully undid the exposure.
