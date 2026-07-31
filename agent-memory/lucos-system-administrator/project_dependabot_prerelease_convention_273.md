---
name: project-dependabot-prerelease-convention-273
description: Estate-wide decision pending on guarding auto-merged base-image bumps (lucos#273); media_import's dependabot ignore rule verified working
metadata:
  type: project
---

lucas42/lucos#273 (open, awaiting lucas42/architect decision) asks which layer should guard against auto-merged pre-release/breaking base-image bumps, after three production incidents: lucos_mail (alpine, stable bump, 2026-06-11), lucos_contacts/lucos_eolas (python pre-release, caught by CI, no outage, 2026-06-23), lucos_media_metadata_manager (php alpha, ~6.5h outage, 2026-07-31 — incident report PR lucas42/lucos#274).

Four repo-local defences exist, no estate convention: media_import (dependabot `ignore`), mail (CI stack-start check, lucos_mail#61), eolas (`FROM app AS test` — tests run in the shipped image), media_metadata_manager (CI grep rejecting alpha/beta/rc tags, #386).

**I verified (2026-07-31) that the media_import ignore rule actually works**, resolving its own comment's hedge ("if this fails silently, fall back to..."): Dockerfile pins `FROM python:3.14` (floating); Docker Hub has had live 3.15 pre-release tags (`3.15.0b3`/`3.15.0b4`/`3.15-rc`) since 2026-07-16; zero Dependabot PRs for `python` opened on that repo since the rule was added 2026-06-11 (daily schedule, ~40 day window). Checked via Docker Hub registry API + repo's PR history, not inferred.

**Why this matters for #273's "which layer" question:** a working ignore rule is silent in both the success and failure case — nothing would have told anyone if Docker Hub's tag format shifted and the wildcard stopped matching. I only confirmed it works by manually checking Docker Hub. This is a concrete point in favour of the CI-assertion / test-in-shipped-image approaches (visible failure = real signal) over dependabot-ignore, even where the ignore syntax happens to be correct today.

**How to apply:** if #273 lands on a decision, don't re-litigate whether media_import's ignore rule "actually holds up" — it's confirmed as of 2026-07-31. The open question is whether silent-suppression is an acceptable trade-off vs a visible-failure guard, not whether the syntax works.
