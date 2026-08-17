---
name: risk-build-time-dependency-reresolution
description: pipenv/npm/etc install without --deploy/--frozen re-resolves deps at build time, silently bypassing Dependabot's review gate — supply-chain risk pattern to check on any repo's Dockerfile
metadata:
  type: project
---

**Pattern**: `RUN pipenv install` (no `--deploy`) in a Dockerfile re-resolves the full dependency graph from `Pipfile` at every build, rather than installing exactly what `Pipfile.lock` pins. Confirmed on `lucos_backups` (2026-08-17): the lockfile *inside the built image itself* disagreed with what was actually installed, across three consecutive images.

**Why it's a security finding, not just reproducibility hygiene**: Dependabot's whole purpose is to put a code-review checkpoint (a PR, a diff, a merge decision) in front of every dependency change. Build-time re-resolution routes around that entirely — *any* commit, even one touching zero Python files (proven: a `github/codeql-action` bump triggered it), can silently pull in a brand-new transitive dependency release with no PR, no diff, no alert. A compromised/malicious PyPI release (typosquat, hijacked maintainer, backdoored point release — `event-stream`/`ua-parser-js`/`xz`-class incidents) would be absorbed automatically. Doesn't cross the private-advisory bar (needs an upstream compromise first, not directly network-exploitable) — routes as a normal public issue.

**Root cause of the 2026-08-17 lucos_backups incident** (15h24m backup outage, zero data loss/exposure): CPython alpha base image (auto-merged as a Dependabot "minor" bump 11 days earlier, latent) + an unrelated commit re-resolved deps and picked up a new `charset_normalizer` wheel the alpha interpreter's C-API couldn't load. See lucas42/lucos_backups#390 (incident), #391 (fix: revert base image), #392 (fix: `pipenv install --deploy`) and lucas42/lucos#289 (incident report, `docs/incidents/2026-08-17-backups-python-alpha-charset-normalizer.md`).

**Check for this pattern**: any repo's Dockerfile using `pipenv install` without `--deploy`, `npm install` without `--frozen-lockfile`/using `ci` correctly, or equivalent for other package managers. **Not yet verified whether this pattern exists elsewhere in the estate** — worth a sweep, but don't assert it's present anywhere beyond `lucos_backups` without checking.

**Related**: [[lucos-creds-scoped-key-permissions]] (a different flavour of "committed state doesn't describe deployed state"). See `feedback-priority-field-vs-severity.md` — I pushed back on #392 being labelled "Not urgent," argue it's a standing review-bypass, not just hygiene.
