---
name: review-self-claimed-state-vs-history
description: When an artifact carries its own claim about its state (ADR Status field, version string, README "current as of"), the claim is authored and can be stale — check git/review history instead, don't take the claim at face value
metadata:
  type: feedback
---

When reviewing or citing any artifact that carries a self-descriptive state claim — an
ADR `Status:` line, a version string, a README's "current as of" note, a comment saying
"this is the live policy" — treat the claim as authored prose, not evidence. Check the
artifact's actual history (git log, PR review list, merge timestamps, linked issue state)
instead of reading the claim and moving on.

**Why:** Confirmed on `lucas42/lucos` ADR-0014 review (2026-08-07). `lucos` ADR-0013 read
`Status: Proposed`. Both `team-lead` and `lucos-architect` independently read that as
"genuinely undecided, awaiting sign-off" and cited it as live policy on 2026-08-06. Neither
had checked the introducing PR's review list. In fact lucas42 had approved
`lucas42/lucos#237` fifteen minutes before it merged — the decision *was* agreed; only the
Status field was stale (it was tracking implementation, not agreement, which is exactly the
conflation ADR-0014 exists to remove). Checking the PR review list directly reversed the
reading and cut the ADR-0014 migration judgement call from 18 ADRs down to 4. I reproduced
this and the rest of ADR-0014's numbers independently before approving — see
lucas42/lucos#275 review — and every claim checked out exactly once measured against the
actual GitHub API state rather than the document's own prose.

**How to apply:** This generalises the existing "verify external state before speculating"
discipline (git tags, PyPI releases, issue open/closed state) to *any* artifact that
describes its own status inline. Before citing a Status/version/currency claim as fact in a
review:
1. Find the artifact's introducing PR or the relevant commit.
2. Check the actual review list / merge timestamp / linked-issue state — not the document's
   own header.
3. If the two disagree, the git/review history wins. The claim is a hypothesis about its
   own state, not proof of it.

This applies whether the artifact is code, an ADR, a persona/skill file, a README, or a
comment describing "current" behaviour. See also [[review_adr_status_is_a_claim]] if a
duplicate exists in the team's shared conventions — this file is the code-reviewer-specific
instance of the same principle, generalised beyond ADRs specifically.
