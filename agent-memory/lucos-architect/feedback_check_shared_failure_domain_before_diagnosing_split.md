---
name: check-shared-failure-domain-before-diagnosing-split
description: Before diagnosing an inconsistency as "two paths, different reliability", check whether both paths share a failure domain
metadata:
  type: feedback
---

When two endpoints/paths return *different* answers to the same question during an incident, do not leap to "path A is fragile, path B is robust — switch to B." First ask: **do both paths share a failure domain?** If they do, the divergence is an artifact of probe *timing*, not a real resilience difference, and "switch to the other path" is a non-fix.

**Why:** On lucas42/lucos_repos#410 (2026-06-07), the code-reviewer reported the auto-merge supervision check (per-repo `/repositories/{repo}` on configy.l42.eu) returned `true` then failed-to-`{}` 3 min apart, while `check-unsupervised` (bulk `/systems`) "stayed correct". I relayed that (correctly hedged as unverified) but then layered an unsound architectural inference on top: "two endpoints, one fact, different reliability → point the workflow at the robust bulk endpoint." SRE's root-cause: it was an estate-wide DNS outage — `*.l42.eu` was unresolvable ~23:34–23:48Z (avalon BIND rejected the l42.eu apex: dns2 defined as both A and CNAME in a stale generated zone). BOTH endpoints live on configy.l42.eu; the bulk one only looked healthy because it was probed from a vantage point with different DNS caching/timing. The per-repo-vs-bulk distinction was pure timing artifact. Switching endpoints would have fixed nothing.

**How to apply:** Self-Verification #6 (review the frame, don't just reason within it). When you catch yourself proposing "use the more reliable component/path/endpoint," verify the two candidates don't fail together first — same host, same domain, same DNS, same network segment. Hedging the *relayed observation* is necessary but not sufficient; the *inference built on it* needs its own check. The real lever here was the OTHER observation — fail-closed-**and-silent** on a transient lookup failure (`curl … || echo '{}'` + `// false` collapsing "couldn't determine" into "supervised") — which SRE endorsed and became lucas42/.github#68. Related: [[feedback_verify_ci_mechanism_before_relying_on_it]], [[feedback_apply_frame_review_to_own_reasoning]].
