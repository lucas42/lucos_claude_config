---
name: No semver-major ignore rules in Dependabot
description: lucas42 does not want semver-major ignore rules added to Dependabot configs — major bumps should flow through normally
type: feedback
originSessionId: 0ce85724-fa7b-4aa8-ab31-0f4bd8fc16ed
---
Do not raise issues proposing `ignore: version-update:semver-major` rules in `.github/dependabot.yml`.

**Why:** lucas42 wants to stay current on all versions including major. If a major bump breaks something, the fix is to improve the tests/build step so CI catches the breakage — not to block the update. Adding ignore rules causes version lag and hides the fact that CI needs improvement.

**How to apply:** If a security audit or post-incident sweep identifies repos without semver-major ignore rules, do not file issues recommending they be added. Instead, if a major-version bump causes a failure, the issue should be about improving CI coverage, not ignoring the version.
