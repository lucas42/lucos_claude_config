---
name: cv-application-privacy
description: Don't expose the names of companies Luke is currently applying to in any public artefact (commits, memory files, filenames, etc.)
metadata:
  type: feedback
---

The names of employers Luke is currently considering or actively applying to are private. They must not appear in any public artefact.

**Why:** Both `lucas42/lukeblaney_cv` and `lucas42/lucos_claude_config` are public repos. Anyone can read their commit history, memory files, and source. Listing employers Luke is targeting tells the world (including those employers and his current employer/network) about his job-hunt activity. Stated 2026-05-20.

**Where the rule applies:**

- **Commit messages** in both repos: never name a specific company Luke is applying to in either the subject or body. Refer to role archetype or JD shape instead.
- **Memory files** in `~/.claude/agent-memory/`: same — these files commit to `lucos_claude_config`. Use role-archetype framings ("a fintech Staff Engineer JD", "a platform-engineering Director JD") rather than employer names.
- **Filenames**: already covered separately — variants use role-archetype names (`cv-staff-engineer.md`, not `cv-fundingcircle.md`).
- **Branch names** and PR descriptions: not currently relevant (no PR workflow), but if introduced, same rule.

**What's exempt:**

- Employers Luke has *already worked at* and lists publicly on his CV (Financial Times, FT Labs, Assanka, Sainsbury's, etc.) — these are already public information via `cv-extended.md`.
- Companies referenced in talks/panels Luke gave or his public website — already public.
- Companies that are subjects of public research, news, or general industry context — not about Luke's applications.

**How to apply:**

Before writing any commit message, memory file content, or anything else that lands in a public repo, ask: "does this name an employer Luke is applying to?" If yes, replace with an archetype:

| Avoid | Use |
|---|---|
| "JD-tuned variant for Funding Circle" | "JD-tuned variant for a Staff Engineer role" |
| "for Partnerize Director of Engineering" | "for a platform-engineering Director role" |
| "the Greenhouse Partnerize JD" | "a Greenhouse-hosted Director JD" |

If in doubt, ask Luke whether a specific employer is OK to name.

Related: [[cv-commit-discipline]].
