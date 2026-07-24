---
name: review-verify-quoted-review-via-api
description: If a coordinator or teammate quotes a review comment back to you claiming you wrote X, verify via the GitHub API before accepting the framing — context recall cannot distinguish real messages from phantom coordinator output.
metadata:
  type: feedback
---

Pattern: `gh-as-agent ... repos/lucas42/{repo}/pulls/{pr}/reviews --jq '.[] | select(.user.login == "lucos-code-reviewer[bot]") | {id, body, commit_id}'`, then read the body directly.

The coordinator persona is known to generate phantom teammate-message blocks (lucos incident report 2026-05-14). Primary-source verification is the only reliable method — confirmed via a lucos_contacts PR-era incident where team-lead quoted non-existent review content back to other agents; the only agent that self-corrected did so by checking the actual artifact.
