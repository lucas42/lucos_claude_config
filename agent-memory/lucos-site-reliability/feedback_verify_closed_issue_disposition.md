---
name: Verify a closed issue's disposition before citing it as evidence
description: When citing a closed issue as evidence of a team preference, design decision, or "won't fix" disposition, read the body and closing comment via the API — checking `state`/`state_reason` alone is not enough.
type: feedback
---

**Rule:** Whenever I cite a closed GitHub issue as evidence for *anything beyond its state* — e.g. "lucas42 closed this signalling a preference to X", "this was rejected as won't-fix", "this disposition shows the team wants Y" — I MUST first fetch the issue body and the closing comment via the API and re-read them. A `state: closed` + `state_reason: not_planned` query is not sufficient.

**Why:** On 2026-05-04 I told team-lead during ops checks that an estate-wide flap pattern matched a "documented" cold-state cascade because lucas42 had closed `lucos_monitoring#186` as `not_planned`, "signalling a preference to live with this residual." Both halves of that claim were wrong:
- I closed `#186`, not lucas42.
- The issue proposed *introducing* the warm-up window, but `#87` had already shipped it months earlier — so the disposition was effectively "duplicate" (closed against work already done), not "we won't extend the warm-up." It carried no signal whatsoever about how anyone feels about the residual cascade.

A one-line `--jq '.state'` check would have told me the issue was closed but nothing about who closed it or why. The drift was in my paraphrase of the *content*, not the state, and that's where verification needs to extend.

**How to apply:** Before paraphrasing a closed issue's disposition in any teammate message, GitHub comment, PR body, or incident report:
1. Fetch the issue body: `gh-as-agent repos/lucas42/<repo>/issues/<N> --jq '{title, state, state_reason, closed_by: .closed_by.login, closed_at, body}'`
2. Fetch the closing comment if there is one: `gh-as-agent repos/lucas42/<repo>/issues/<N>/comments`
3. Read what the issue actually proposed and what the closer said. If the closing comment is just "closed" or empty, the disposition is not strong evidence — say so explicitly rather than inferring.
4. If you can't justify your paraphrase from the body + closing comment alone, drop the citation rather than dressing memory up as documentation.

This is an extension of the existing "verify issue state before citing it" rule (in MEMORY.md) — that one catches stale `open/closed` claims; this one catches stale paraphrases of *what the issue was about and how it was resolved.*
