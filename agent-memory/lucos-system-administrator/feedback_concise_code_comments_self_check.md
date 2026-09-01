---
name: feedback_concise_code_comments_self_check
description: caught by lucas42's review for writing a 7-line rationale comment in a config file instead of the commit message
metadata:
  type: feedback
---

Wrote a 7-line comment block in `.circleci/test-deploy.yml` (lucos_deploy_orb#195/PR #201) explaining why an assertion changed — full rationale, background, and future-proofing argument, all in-code. lucas42 requested changes: "This comment is too verbose. Not sure any of it is useful — an explanation of why a change was made belongs in the commit message, not a comment in the code base."

**Why:** the workflow doc (`agents/workflows/implement-issue.md`) already states this rule explicitly ("Keep in-code comments to one line, two at most... Decision rationale belongs in the commit message") — I had it available and didn't apply it, because the commit-message habit didn't carry over to inline comments in the same change.

**How to apply:** before committing any diff that adds a code/config comment, re-read the comment in isolation and ask "would this survive as one line?" If the explanation needs more than that, it belongs in the commit message (which I was already writing in full for the same change) — never duplicate it in-code. Applies to YAML comments as much as source code. This is a self-check to run at the moment of writing the comment, not just a rule to recall after being corrected.
