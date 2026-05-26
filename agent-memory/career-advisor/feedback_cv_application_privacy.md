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

**Critical: the scan applies BEFORE every Write/Edit tool call, not at commit time.** Auto-commit hooks on `~/.claude` can fire between a Write/Edit and a follow-up redaction — once the file is on disk with an employer name, a hook may commit it before you get a chance to clean up. The submission memory sweep ([[submission-memory-sweep]]) includes a privacy scan as its final backstop, but by then mid-session writes may already have leaked into history. **Write with the placeholder from the start; never write the real name and "redact later".**

This applies to BEFORE each Write or Edit tool call that touches:

- `~/.claude/agent-memory/` (any career-advisor memory file)
- `~/.claude/skills/` (any skill file, especially examples)
- Any other public repo

Specifically:

- Writing a new feedback memory mid-session → write the redacted version directly. Don't write with the real name "and clean it up later" — the auto-commit hook may have committed before you get to the redaction.
- Updating an existing memory mid-session (e.g. appending a new defensible skill, framing rule, or voice nuance during a per-application consultation) → write the redacted addition. Don't put the real name in the Edit's `new_string` thinking you'll fix it before commit.
- Updating a skill file with example-based language → scan for employer names BEFORE the Write/Edit call.
- Writing a commit message that describes per-application work → scan the message body before passing to `git commit`.

Stated 2026-05-23 after I leaked the target employer's name into 3 memory files and 2 commit messages during the form-probe-driven /tailor work, on the implicit (wrong) assumption that the privacy scan only applied at submission sweep. **Tightened 2026-05-26** after an auto-commit hook fired between a memory-file Write call and my follow-up redaction Edit, leaking an employer name to public history for ~30 minutes. The fix: don't write the real name then redact — write with the placeholder from the start, so there's no window in which the real name exists on disk in a public-repo working tree.

Replacement framings — two styles, both acceptable; pick whichever fits the example:

**Style A — role-archetype / industry-archetype**:

| Avoid | Use |
|---|---|
| "JD-tuned variant for [Fintech Co]" | "JD-tuned variant for a Staff Engineer role" |
| "[Broadcaster X]'s Enablement team letter" | "a public-service broadcaster cover letter" |
| "[Transport Operator Y]'s Principal Engineering Cyber Security" | "a transport-sector cyber-security leadership letter" |
| "[Non-Profit Z]'s developer platform" | "an open-knowledge non-profit's developer platform" |
| "[Pensions Provider W]'s regulated-industry framing" | "a regulated-pensions cover letter" |

**Style B — fictional named entities** (Luke's stated preference where a named example reads more concretely than an archetype, 2026-05-21):

| Avoid | Use |
|---|---|
| "applied to [Fintech]" | "applied to Acme Corp" (or "Acme Invest" if the retail-investing-domain signal matters) |
| "the [Hospitality Co] draft" | "the Beta Hosts draft" |
| "the [Lending Co] Staff IC variant" | "the Gamma Lending Staff IC variant" |
| "the [Pensions Provider] letter" | "the Delta Pensions letter" |

When the industry / domain context matters for the example to land, encode it in the fictional name (e.g. "Acme Invest" for retail investing, "Gamma Lending" for a lending fintech) or pair the fictional name with an archetype descriptor. When the industry doesn't matter, "Acme Corp" is the universal placeholder.

**Don't list live-application paths by real employer slug.** When memory files reference `lukeblaney_cv_tailored/orgs/{employer}/` directories, use role-archetype descriptions of the variant rather than naming the employer-slug. The private repo's filesystem can name employers freely; the public memory file's *prose* about it should not.

**Live tailored drafts:**

Individual cover-letter and CV drafts for specific live applications go in `lucas42/lukeblaney_cv_tailored` (private repo, set up 2026-05-20). That repo can name employers freely — it's only the public artefacts where the default-deny applies.

Related: [[cv-commit-discipline]], [[cover-letter-rebuild]].
