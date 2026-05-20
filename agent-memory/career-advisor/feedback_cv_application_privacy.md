---
name: cv-application-privacy
description: Default-deny rule for employer names in public artefacts — ANY employer name needs explicit sign-off before it lands in a public commit
metadata:
  type: feedback
---

**Default-deny rule:** Any employer name landing in a public artefact (commit message, memory file, repo file content, branch name, PR description) requires explicit sign-off from Luke first. This applies regardless of whether the employer is a current target, a past application, or just an industry mention. When in doubt, ask — don't commit.

**Why:** Both `lucas42/lukeblaney_cv` and `lucas42/lucos_claude_config` are public repos. Anyone can read their commit history, memory files, and source. Naming employers — current targets, past applications, or even speculative mentions — signals Luke's job-hunt activity to those employers, his current employer, his network, and the world. Past applications can still be future application targets, and the public record persists indefinitely.

Stated 2026-05-20. Tightened from a narrower "currently applying to" rule after I leaked eight employer names from a review of Luke's previous letters into a memory commit, on the implicit (wrong) assumption that past applications were out of scope.

**Where the rule applies:**

- **Commit messages** in both repos: never name an employer. Refer to role archetype or JD shape instead.
- **Memory files** in `~/.claude/agent-memory/`: same — these files commit to `lucos_claude_config`. Use role-archetype framings ("a fintech Staff Engineer JD", "a platform-engineering Director JD", "a transport-sector cover letter") rather than employer names.
- **Repo file content** in `lucas42/lukeblaney_cv` (cover-letter blocks, templates, etc.): same. Patterns and examples use role-archetype or industry-archetype labels.
- **Filenames**: variants use role-archetype names (`cv-staff-engineer.md`, not `cv-fundingcircle.md`).
- **Branch names** and PR descriptions: same rule.

**What's exempt (no sign-off needed):**

- Employers Luke has *already worked at* and lists publicly on his CV (Financial Times, FT Labs, Assanka, Sainsbury's, etc.) — these are already public information via `cv-extended.md`.
- Companies referenced in talks/panels Luke gave, his public website, or his published work — already public.

**How to apply:**

Before writing any commit message, memory file content, or repo file content, scan for employer names. If any are present and not on the exempt list, **stop and ask Luke**. Don't assume "this one's fine because [reason]" — the default is to redact.

Replacement framings:

| Avoid | Use |
|---|---|
| "JD-tuned variant for [Fintech Co]" | "JD-tuned variant for a Staff Engineer role" |
| "[Broadcaster X]'s Enablement team letter" | "a public-service broadcaster cover letter" |
| "[Transport Operator Y]'s Principal Engineering Cyber Security" | "a transport-sector cyber-security leadership letter" |
| "[Non-Profit Z]'s developer platform" | "an open-knowledge non-profit's developer platform" |
| "[Pensions Provider W]'s regulated-industry framing" | "a regulated-pensions cover letter" |

**Live tailored drafts:**

Individual cover-letter and CV drafts for specific live applications go in `lucas42/lukeblaney_cv_tailored` (private repo, set up 2026-05-20). That repo can name employers freely — it's only the public artefacts where the default-deny applies.

Related: [[cv-commit-discipline]], [[cover-letter-rebuild]].
