---
name: No semver-major ignore rules in Dependabot
description: No semver-major ignore rules in Dependabot — but this does NOT extend to pre-release/beta bumps, which are a different class
type: feedback
originSessionId: 0ce85724-fa7b-4aa8-ab31-0f4bd8fc16ed
modified: 2026-08-08T11:56:41.553Z
---
Do not raise issues proposing `ignore: version-update:semver-major` rules in `.github/dependabot.yml`.

**Why:** lucas42 wants to stay current on all versions including major. If a major bump breaks something, the fix is to improve the tests/build step so CI catches the breakage — not to block the update. Adding ignore rules causes version lag and hides the fact that CI needs improvement.

**How to apply:** If a security audit or post-incident sweep identifies repos without semver-major ignore rules, do not file issues recommending they be added. Instead, if a major-version bump causes a failure, the issue should be about improving CI coverage, not ignoring the version.

**Boundary — this rule does NOT extend to pre-release/beta bumps.** Do not cite it to reject a pre-release guard. The majors-flow policy rests on **CI being a meaningful signal** for that class of change: a major bump is between two releases the vendor has shipped and stands behind, so a build/test failure is good evidence of real incompatibility. Pre-releases differ in kind, not degree — the base-image incidents behind lucas42/lucos#273 (php alpha missing `mbstring`, python beta missing `libpq`, an alpine bump) all **built successfully and broke at runtime**, which is exactly what CI is blind to. "A pre-release base image requires a human decision" is therefore the *same* principle as letting majors flow (trust CI where its signal means something), not an exception to it.

**Where a pre-release occurrence should go:** route it to lucas42/lucos#273 as another data point, NOT to a per-repo `ignore:` rule. #273 exists to converge four already-existing parallel per-repo mechanisms onto one estate-wide answer, so a bespoke `ignore:` block adds a fifth and pre-empts the decision with the layer that thread leans away from. A further reason it was rejected: a working `ignore` rule is silent in both directions — nothing announces if it quietly stops matching, whereas a CI assertion fails loudly and leaves a sweepable artefact. (Established on lucas42/lucos_creds#512, 2026-08-08, by `lucos-system-administrator`; `python:3.15.0b2` was the same upstream tag that had already broken lucas42/lucos_contacts#741 and lucas42/lucos_eolas#311.)
