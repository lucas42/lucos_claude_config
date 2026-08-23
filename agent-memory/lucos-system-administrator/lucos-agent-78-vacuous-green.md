---
name: lucos-agent-78-vacuous-green
description: lucas42/lucos_agent#78 — should a partial-coverage test report success at all? Owner=me, Needs Analysis, Medium.
metadata:
  type: project
---

Filed by team-lead 2026-08-23 off my flag on lucos_agent#77's review: `tests/arachne-mcp-proxy`'s missing-`.env` path exits 0 right after skipping Test 2, so Test 3 never runs in CI either — "CI green" doesn't mean the MCP round-trip was exercised.

**Team-lead's reframe (mine to push back on if I disagree, but I don't):** split into two independent questions, only one of which is a credentials decision:
1. Should a test script that can't run its main assertions report success at all? (No credential implications — a script that ran 1 of 3 tests could exit non-zero, or CI could assert *which* tests ran.) This is the actual scope of #78.
2. Should `.env` be provisioned to CI so the full round-trip runs? (Credentials-in-CI decision — triggers the `lucos-security` specialist-routing gate per estate rules. Explicitly NOT bundled into #78.)

**Wider pattern, worth re-reading before starting #78's analysis:** team-lead named this as the fourth same-shape instance in one session (CircleCI insights endpoint default-branch-only, monitoring's `circleci` fetcher scoped to `branch=main`, [[lucos-agent-coding-sandbox-no-deploy-path]]'s webhook gap, now this). Each reads as coverage while covering less than it appears to, and each was only found by someone checking what the signal actually measures — never by the signal itself going red. The useful framing for #78 is "what should a partial run report", not "how do we get full coverage" — that generalises past this one script.

**How to apply:** when #78 comes up, don't jump straight to "make Test 2/3 exit non-zero without creds" (that just makes CI red for a reason nobody asked to fix, per [[lucos-agent-coding-sandbox-no-deploy-path]]'s sibling lesson). Read the actual issue body when it's assigned — this memory is a pointer, not the analysis.
