---
name: Issue-body sequence labels autolink to real unrelated issues
description: Never write `#1`/`#2`/`#3` as sequence labels in a multi-issue series — GitHub autolinks them to real (and almost always unrelated) issues in the same repo
type: feedback
---

When drafting a series of related issues to file together (ticket 1 / ticket 2 / ticket 3), do **not** use `#1`, `#2`, `#3` as ordinal sequence labels in the body markdown. GitHub silently autolinks every `#N` in issue/PR/comment markdown to issue number N in the current repo. On any active repo, those low numbers will resolve to real, unrelated tickets from years ago, and the corruption is invisible in the source.

**Why:** Caught the night I filed lucos_contacts #699/#700/#701 — initial bodies of #700 and #701 used `#1`/`#2` as sequence references back to the ones earlier in the series. PATCH-fixed before triage, but it's the same class of footgun as the `gh api` `{owner}/{repo}` template substitution: silent, downstream, invisible at draft time.

**How to apply:** Two safe patterns when filing a multi-issue series. (a) File the earlier issues first, then reference their real numbers in subsequent bodies. (b) Draft with non-`#` placeholders like `[seq-1]` / `[seq-2]` and substitute real numbers as you file. If you've already filed a body containing sequence labels, fix via PATCH on `repos/{owner}/{repo}/issues/N` before any triage step touches the issue. Treat this as a check whenever a body contains references to "ticket 1" / "ticket 2" / "the earlier ticket" — search for any bare `#N` and verify it points where you intended.

Instruction file updated: `~/.claude/references/issue-creation.md` step 3 now documents this. So this memory is the secondary defence; the reference doc is the primary one.
