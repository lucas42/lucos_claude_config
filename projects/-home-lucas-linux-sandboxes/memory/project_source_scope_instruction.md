---
name: project-source-scope-instruction
description: Pending estate-wide instruction on confident negatives from scope-limited sources; the wording must catch both directions
metadata: 
  node_type: memory
  type: project
  originSessionId: ec244e45-7257-4a34-8a03-350d242bb3e6
  modified: 2026-08-23T10:35:30.707Z
---

`lucos-site-reliability` is to file an issue (next time they are active after
2026-08-23) proposing an estate-wide rule: **before concluding "it never
happened", establish what the source's scope actually is** — a default-branch-only
source cannot tell you about branches, and it answers confidently rather than
erroring. Routing agreed: raise as an issue, land it in
`agents/common-sections-reference.md`, then a `lucos-system-administrator`
consistency audit propagates it. Not a per-persona hand-edit. They hold a
matching pending-action note (commit `35b6e1b`).

**When triaging that issue, check the wording catches BOTH directions** — this
is the part that exists only in a SendMessage and may not reach the issue body:

- *Queried and got nothing, therefore nothing happened.* (CircleCI's insights
  endpoint silently ignoring `all-branches=true`; `lucos_monitoring`'s
  `circleci` fetcher requesting `pipeline?branch=main`.)
- *Asserted coverage without querying at all.* (My "in both occurrences the
  check alerted" on `lucas42/lucos#290`.)

Same conclusion — a confident negative about a region the source never covered —
reached with and without a query. Wording that only addresses careless API use
misses the half that involves no API call. Three instances across three agents
in one day is what earned it estate-wide altitude.

Related: [[feedback_treat_empty_tool_output_as_unknown]],
[[feedback_verify_before_propagating]].
