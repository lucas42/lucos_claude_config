---
name: contrast-ratio-verification
description: Hand-calculated contrast ratios must be verified against WebAIM or similar before claiming them in a PR test plan
metadata:
  type: feedback
---

Never assert a specific contrast ratio in a PR test plan from hand calculation alone. The sRGB luminance formula has enough floating-point nuance that back-of-envelope arithmetic produces subtly wrong results — e.g. `#c49000` on white was calculated as 3.05:1 but the correct value is 2.86:1, causing a PR CHANGES_REQUESTED.

**Why:** A wrong ratio claim in the test plan becomes a blocker: the reviewer has to refute it, the PR stalls, and a fix commit is needed for something that should have been right the first time.

**How to apply:** Before writing a contrast ratio into a test plan or PR description, verify with [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) or equivalent. If unable to run the checker, omit the specific ratio and describe the relationship qualitatively ("darker than `#c49000`, confirmed passing 3:1 against white") — or hedge explicitly ("approximately X:1, to be verified").
