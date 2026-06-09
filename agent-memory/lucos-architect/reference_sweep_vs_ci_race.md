---
name: sweep-vs-ci-race
description: required-status-checks-coherent false positives from sweep-vs-CI race, not stale cache (lucos_repos#413)
metadata:
  type: reference
---

The daily `lucos_repos` audit sweep and estate-wide dependabot auto-merges both fire at **~07:15 UTC**. They collide: the sweep reads HEAD of main while CI is still in flight on the just-merged commit.

`required-status-checks-coherent` (Step 2, stale-name sub-check) then false-positives — a required check (e.g. `ci/circleci: lucos/build`, the CircleCI **workflow-rollup** status, which posts *last*, ~5 min after merge) is genuinely absent on the brand-new HEAD while faster checks have already reported, so the `len(reported) > 0` guard doesn't suppress it. Recurs daily on repos with slow rollup checks + dependabot merges in the window (arachne is the reliable case).

- **It is NOT a stale cache.** httpcache.go's CachingTransport is in-memory + per-sweep — nothing persists across sweeps. When handed a "stale cache" framing, verify the cache lifecycle before accepting it. (Instance of [[feedback_verify_ci_mechanism_before_relying_on_it]].)
- Fix tracked in lucos_repos#413: look-back window (flag stale only if absent from recent prior commits, not just HEAD), triggered only when a check looks missing on HEAD (zero extra API cost otherwise). Precedent: Step 4's dependabot sub-check already does this via its `BaseCheckNames` timing-artefact logic.
- Secondary mitigation (not the real fix): separate the sweep schedule from the dependabot auto-merge window.
- Cost of tolerating: ADR-0004 auto-close cleans up but doesn't stop the re-raise; daily cry-wolf on a security/reliability convention trains everyone to ignore a real stale-check finding.
