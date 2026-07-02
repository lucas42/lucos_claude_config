---
name: review-specialist-signoff-artifact
description: a specialist's SendMessage confirmation is not a sign-off — only a GitHub review/comment on the PR counts
metadata:
  type: feedback
---

A SendMessage confirmation from lucos-security or another specialist is NOT a sign-off. SendMessage is not visible to the user, is not in the PR history, and is not auditable after the session ends.

**How to apply:** when a specialist confirms via SendMessage that a PR is fine, ask them to post a GitHub review or comment on the PR itself, then wait for that URL before reporting "signed off" to the team-lead or in a completion report. If you only have a SendMessage confirmation, say so explicitly — "security confirmed via SendMessage but has not yet posted on the PR — chasing them for a visible review" — rather than reporting sign-off as done.
