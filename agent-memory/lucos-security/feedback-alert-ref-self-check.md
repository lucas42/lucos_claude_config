---
name: feedback-alert-ref-self-check
description: Even a fully-qualified owner/repo#N for a Dependabot/CodeQL alert number is wrong — alert numbers aren't in the issue/PR namespace, so it can silently point at a real unrelated issue/PR.
metadata:
  type: feedback
---

On tfluke#528 (2026-09-13, the js-yaml/CVE-2026-84375 fix) I wrote a Dependabot alert number in `owner/repo#N` form in the PR body — twice. The persona file and MEMORY.md already state the rule ("never use `#N` for Dependabot/CodeQL/secret-scanning alerts — use the CVE/GHSA id"), so this wasn't a missing instruction, just a lapse under the pull of "fully-qualifying the repo name feels like the safe/correct form." That number happened to belong to a real, unrelated, already-closed PR in the same repo, so the reference wasn't a dead link — it silently cross-linked to the wrong thing. Caught by lucos-code-reviewer, not by me.

It then **recurred the very next day** in an ops-check completion manifest (2026-09-14), despite an instruction fix landing in between. Root cause of the recurrence, traced 2026-09-14: my own memory notes about this incident (this file and `risk-npm-lockfile-version-drift.md`) had themselves recorded the alert using its `#N` form as a casual shorthand label. `ops-checks.md` gets re-read at the start of every ops-check run, so that label was back in front of me minutes before I drafted the manifest, and I reached for the familiar shorthand instead of the GHSA id — the self-check pass caught fresh mentions but not a label already internalised from my own prior notes.

**Why:** alert numbers (Dependabot/CodeQL/secret-scanning) live in a separate numbering space from issues/PRs on GitHub. Qualifying with `owner/repo#N` fixes the *cross-repo* ambiguity but does nothing about the *alert-vs-issue* ambiguity — those are two different failure modes the same-looking token can hit. And the rule doesn't stop applying just because you're closing out or referring back to an alert you already discussed earlier — a label picked up once keeps resurfacing every time the topic comes back, including from your own notes.

**How to apply:** before posting any PR/issue body, comment, or teammate message that mentions a Dependabot/CodeQL/secret-scanning alert — including a closing remark about one that's already resolved — grep my own draft for the alert's number pattern (`#<N>` or `repo#<N>`) and swap every hit for the GHSA/CVE id or the full alert URL. Also **never write the alert in `#N` form into my own memory files** — write it as the GHSA/CVE id (or, once a fix PR exists, just cite that PR's number instead) so a later re-read doesn't hand the bad label straight back to me.
