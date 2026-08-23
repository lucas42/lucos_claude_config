---
name: establish-source-scope-before-never-happened
description: Before concluding "it never happened" from a data source, establish what that source's scope actually is — scoped sources answer confidently rather than erroring. Includes a pending action to raise this estate-wide.
metadata:
  type: feedback
---

**Before concluding *it never happened* / *it has never failed* / *there is no record of X*, establish what the source's scope actually is.** A source scoped to a subset does not error when asked about the whole — it answers confidently about its subset, and the answer is indistinguishable from a real negative.

**Why:** three instances in one day (2026-08-23), across three sources and three agents, all the same shape — a default-branch-only source read as though it covered every branch:

1. **Mine, CircleCI insights.** `/insights/.../jobs/test` reports the default branch only and **silently ignores `all-branches=true`** — byte-identical output with and without the flag. I published "has not failed in CI once in 90 days" to a PR body and to lucos-code-reviewer. It had red'd 5 days earlier and blocked a Dependabot PR for 38h48m.
2. **Mine again, 4 hours later, monitoring's fetcher.** `lucos_monitoring/src/fetcher_circleci.erl:73` requests `?branch=main&limit=5`, so the `circleci` check cannot see a PR-branch pipeline.
3. **team-lead's, in lucas42/lucos#290.** Asserted "in both occurrences the `circleci` check alerted correctly and immediately" by assuming a monitoring check's coverage rather than reading its scope. Corrected 2026-08-23.

**How to apply:** the tell is a negative claim resting on a query returning nothing. Before publishing it, read the source's scope — the URL's query string, the fetcher's source line, the endpoint's docs. Two corroborating queries that *should* differ but return identical output is a symptom, not confirmation. Prefer the purpose-built history source over a dashboard aggregate (see [[feedback-verify-state-file-semantics-before-reading-history]]). Pairs with [[feedback-verify-check-claim-against-underlying-store]] and [[feedback-treat-empty-tool-output-as-unknown]] — that one covers empty output meaning *unknown*; this one covers non-empty output that is confidently, invisibly partial.

⏳ **PENDING ACTION, agreed with team-lead 2026-08-23 — raise next time active, do not hand-edit.** They asked for this lifted above any one persona; I had filed it only in `agents/sre-circleci-api.md`, which made it a CircleCI fact rather than a general rule. A cross-cutting instruction change routes via `agents/common-sections-reference.md` plus a sysadmin consistency audit, so it must be **raised as an issue** for team-lead to triage, not edited directly. They said no urgency and explicitly not that session. If already filed or landed, delete this block.
