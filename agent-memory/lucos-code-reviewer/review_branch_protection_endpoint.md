---
name: review-branch-protection-endpoint
description: Both a schema difference AND a per-App permission difference are real on branch-protection endpoints — always self-serve required status checks via /branches/{branch}, never rely on /protection or on required_pull_request_reviews being null
metadata:
  type: reference
---

**Two independent, both-real facts, don't collapse them into one:**

1. **Schema:** `repos/{owner}/{repo}/branches/{branch}` embeds a `.protection` object with only ~3 keys (`enabled`, `required_status_checks`, `enforcement_level`). The dedicated `.../branches/{branch}/protection` endpoint returns the full ~11-key object. Both expose `required_status_checks.contexts` identically.
2. **Permissions:** the `/protection` sub-path genuinely does vary by App — `lucos-site-reliability`'s App reads it fine; `lucos-architect`'s and `lucos-issue-manager`'s both 403 on it (each independently confirmed 200 on `/branches/{branch}` in the same test). So "which App you are" *does* gate the full-schema endpoint — it just doesn't gate the smaller embedded one.

**Practical upshot, unaffected by which axis is in play:** call `/branches/{branch} --jq '.protection'` for required status checks — it's readable by every App tested and sufficient for that purpose. Never route a required-checks read through another agent "because my App can't see it" — check `/branches/{branch}` first; only fall back to asking an App with `/protection` access (SRE's, or `lucos-system-administrator`) if you specifically need a field that's absent from the smaller schema, like `required_pull_request_reviews`.

**`required_pull_request_reviews: null` from `/branches/{branch}` is not evidence of anything — the key is simply absent from that smaller schema, and `jq` renders a missing key identically to a `null` value.** Do not read it as "this branch has no review requirement." Use the `lucos_repos` `branch-protection-enabled` convention (protection without requiring approvals) as the working assumption instead, or ask an App that can read `/protection`.

**Why this matters:** across one evening (`lucos_worlds#67`, 2026-08-06) three of us each ran a confounded comparison trying to explain a 403 or a `null`, and the explanation got revised multiple times before landing on "both a schema gap and a permissions gap exist, independently" — architect compared a draft PR against a non-draft one from a different week and blamed draft status; I compared my `/branches/{branch}` result against architect's `/protection` result and concluded my App had broader access (wrong: it was the endpoint); SRE then over-corrected to "it's purely schema, not permissions" (also wrong: the sub-path permission gap is real too, confirmed by testing a third App). The generalisable lesson: when two calls disagree, check *both* whether they hit the same endpoint *and* whether the same App made both calls before attributing the difference to either alone — and be suspicious of a tidy single-cause "actually it's just X" correction arriving fast, since the truth here needed two non-exclusive causes.
