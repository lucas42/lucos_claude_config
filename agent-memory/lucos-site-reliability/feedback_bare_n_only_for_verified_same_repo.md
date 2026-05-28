---
name: feedback-bare-n-only-for-verified-same-repo
description: Bare `#N` in a same-repo file auto-links to that repo's #N, which is often a real-but-unrelated issue. Qualify any cross-repo reference even after establishing context earlier in the same paragraph; GitHub auto-links each instance independently.
metadata:
  type: feedback
---

When writing in a lucos-repo file (e.g. an incident report), the bare `#N` form is **only** safe when N refers to a lucos issue/PR that I've actually checked. Otherwise it auto-links to an unrelated lucos issue.

**Sub-rule that bit on PR #201:** even if you write `lucas42/lucos_claude_config#100` earlier in the same paragraph, a subsequent bare `#100` in the same paragraph does **not** inherit that context. GitHub auto-links each `#N` instance independently against the host repo, so the second mention still mis-links to lucos#100 (which is "Migrate auto-merge workflows to LUCOS_CI credentials," entirely unrelated).

**How to apply:**

1. Before shipping any incident report, PR description, or other lucos-repo-hosted artifact: grep for `(^|\s)#\d+` (bare `#N` preceded by whitespace or start-of-line) and verify each instance.
2. For each match, check whether N refers to:
   - a lucos issue/PR I intended → keep as bare `#N`;
   - a cross-repo issue/PR → qualify as `lucas42/<repo>#N`, OR rewrite as plain prose (e.g. "PR #99 in `lucos_claude_config`") if the section already names the repo and qualifying would be visually noisy.
3. Don't trust "I qualified it once earlier in the paragraph" — every instance auto-links independently.

**Provenance:** caught by code-reviewer three times in three days on the xwing incident-report PRs:
- PR #198 (initial report) — bare `lucos#192` / `lucos#179` should be bare `#192` / `#179`
- PR #200 (TBD-fill) — first PR I held to it consistently
- PR #201 (final amendment) — Final state section had `lucos_repos#404` (missing owner) and `(#99/100/101)` (bare; would mis-link to lucos#99/100/101)

Related: [[feedback_refetch_state_before_writing_final_artifact]] — also caught on the xwing incident; the broader pattern is "stop assuming caching of any kind in a final artifact — re-check each individual reference."
