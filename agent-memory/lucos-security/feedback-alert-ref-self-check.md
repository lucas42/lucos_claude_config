---
name: feedback-alert-ref-self-check
description: Even a fully-qualified owner/repo#N for a Dependabot/CodeQL alert number is wrong — alert numbers aren't in the issue/PR namespace, so it can silently point at a real unrelated issue/PR.
metadata:
  type: feedback
---

On tfluke#528 (2026-09-13, the js-yaml/CVE-2026-84375 fix) I wrote `lucas42/tfluke#61` for Dependabot alert #61 in the PR body — twice, including as `Refs lucas42/tfluke#61`. The persona file and MEMORY.md already state the rule ("never use `#N` for Dependabot/CodeQL/secret-scanning alerts — use the CVE/GHSA id"), so this wasn't a missing instruction, just a lapse under the pull of "fully-qualifying the repo name feels like the safe/correct form." `#61` in tfluke happened to be a real, unrelated, already-closed PR, so the reference wasn't a dead link — it silently cross-linked to the wrong thing. Caught by lucos-code-reviewer, not by me.

**Why:** alert numbers (Dependabot/CodeQL/secret-scanning) live in a separate numbering space from issues/PRs on GitHub. Qualifying with `owner/repo#N` fixes the *cross-repo* ambiguity but does nothing about the *alert-vs-issue* ambiguity — those are two different failure modes the same-looking token can hit.

**How to apply:** before posting any PR/issue body or comment that mentions a Dependabot/CodeQL/secret-scanning alert, grep my own draft for the alert's number pattern (`#<N>` or `repo#<N>`) and swap every hit for the GHSA/CVE id or the full alert URL — do this as a explicit final pass, the same way `agent-github-identity.md` already tells me to re-fetch and check a posted comment for corruption. Don't rely on "I know the rule" carrying through into the actual draft.
