# lucos-security Agent Memory

## Infrastructure: Repo Visibility

All lucos repos on github.com/lucas42 are **public**. This is critical context for every security review:
- Documentation committed to repos (including `docs/reviews/`, ADRs, CLAUDE.md) is publicly readable
- GitHub issue trackers, including closed issues, are publicly readable
- Git history (including PR commit history) is permanent and publicly searchable
- Sensitive security findings must go to GitHub Security Advisories (private by default), NOT public issues or committed files

## Architecture Pattern: Sensitive Findings in Public Repos

For architectural reviews stored in `docs/reviews/` (agreed convention per lucas42/lucos#24):
- Structural/design observations: fine to commit publicly
- Incomplete/broken security controls, ambiguous auth, unprotected endpoints: should go to private GitHub Security Advisory instead
- The review template should include an explicit "Sensitive findings" section linking to any advisory (or "None")
- Git history is permanent -- sensitive content accidentally drafted must be purged with a history rewrite, editing-and-committing is not sufficient

## Process: GitHub Security Advisories

GitHub Security Advisories (under repo Security tab) are the correct home for:
- Findings about currently exploitable vulnerabilities
- Details of auth mechanisms that are incomplete or ambiguous
- Internal endpoint details, especially unauthenticated ones
- Any finding that describes a known gap not yet fixed

A consistent Security Advisory practice across lucos repos is tracked in lucas42/lucos#25.

## Key People/Agents

See `relationships.md` for notes on working with other lucos agents.
