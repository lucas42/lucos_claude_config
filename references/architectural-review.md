# Architectural Review Process

This file is read by `lucos-architect` when conducting architectural reviews.

## Where Reviews Live

Reviews are stored in `docs/reviews/` in the repo being reviewed. This is separate from `docs/adr/` (which holds Architecture Decision Records). ADRs record decisions; reviews record assessments. They are related but structurally different artefacts.

## Filename Convention

`YYYY-MM-DD-review.md` (e.g. `2026-02-28-review.md`). If multiple reviews occur in the same month, append a suffix.

## Review Template

```markdown
# Architectural Review: {repo_name}

**Date:** YYYY-MM-DD
**Reviewer:** lucos-architect[bot]
**Commit:** {short_hash}

## Summary

[2-3 sentence overall assessment]

## Strengths

[Bulleted list of things that are working well]

## Concerns

[Bulleted list of concerns, each with a brief explanation]

## Sensitive findings

[Link to private GitHub Security Advisory if applicable, otherwise: "None."]

## Issues raised

| Issue | Title | Severity | Status |
|---|---|---|---|
| #N | ... | High/Medium/Low | Open / Closed -- reason |

## Comments on existing issues

| Issue | Title | Topic | Status |
|---|---|---|---|
| #N | ... | ... | Open / Closed -- reason |
```

The "Sensitive findings" section is mandatory. Every review explicitly records whether there are findings that should not be public.

Whether a finding warrants a private advisory rather than a public issue depends on two criteria: (1) an attacker with network access could exploit it immediately without any prior access, and (2) it is not yet fixed. If both are true, it goes in a private GitHub Security Advisory — never in the committed review file. Everything else — conditional exploitability, defence-in-depth gaps, theoretical chains — goes as a normal public issue. See `docs/security-findings.md` in the `lucos` repo for the full decision rule.

## Workflow

1. Conduct the review, reading the codebase and identifying concerns.
2. File individual GitHub issues for each actionable finding. These are the work items.
3. Write the review summary as a Markdown file in `docs/reviews/`. Keep it concise — the detail belongs in the individual issues.
4. Submit a PR to add the file. The PR description links to the issues raised. **Do not create a summary issue.**
5. The PR is the reviewable artefact. Once merged, the file is the permanent record.

## Critically Appraising CLAUDE.md

When reviewing a codebase, treat its `CLAUDE.md` file as part of the architecture — not as a given. The other agents follow `CLAUDE.md` instructions without question, and that is appropriate for their roles. But as the architect, your job is to take a step back and question underlying assumptions.

During a review, read the repo's `CLAUDE.md` and ask:
- **Is it accurate?** Does it reflect how the codebase actually works, or has it drifted?
- **Is it complete?** Are there important architectural constraints or conventions that are missing and should be documented?
- **Is it misleading?** Could any instruction lead an agent to make a poor decision because it oversimplifies or encodes a past assumption that no longer holds?
- **Does it conflict with broader conventions?** Does it contradict the global `CLAUDE.md` or established lucos infrastructure patterns without good reason?
- **Is it proportionate?** Is it the right length and level of detail for the repo, or has it accumulated cruft?

If you find problems, raise them as concerns in the review and file issues as you would for any other finding. A `CLAUDE.md` that gives agents bad instructions is an architectural problem — it shapes every contribution those agents make.

## Discoverability

When adding a review to a repo for the first time, also add a one-line pointer to the repo's CLAUDE.md (or equivalent documentation): "Architectural reviews are in `docs/reviews/`." This ensures anyone working in the repo knows where to look without having to know the convention in advance.
