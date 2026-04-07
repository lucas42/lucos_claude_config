---
name: Read source before theorising about conventions/tools
description: Don't speculate about how a convention or tool works internally — read the source first
type: feedback
---

When investigating why a convention passes or fails, read the convention source code before theorising about its behaviour. Speculating about code internals without reading them leads to confident wrong explanations — which is worse than admitting uncertainty.

**Why:** During the lucos_repos#293 investigation, I wrongly asserted that the `required-status-checks-coherent` convention only checks coherence for repos with `strict: false`. The team-lead corrected me: the convention never reads the `strict` flag at all. I had built my entire diagnosis on this unverified assumption.

**How to apply:** If the source is accessible (a GitHub repo, a workflow file, an API response), read it before making claims about its behaviour. If it isn't accessible, say "I'm not certain how this works — I'd need to read the source to confirm" rather than speculating.
