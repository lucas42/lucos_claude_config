---
name: feedback-shared-global-side-effects
description: check whether a changed global/shared config value is read by callers outside the PR's own diff before approving
metadata:
  type: feedback
---

Before approving a PR that changes what a package-level/global mutable value gets set to — even when the diff is scoped to one call site and precisely matches a pinned spec — check whether that same global is read by *other* code paths not touched in the diff, especially a live/request-serving path sharing state with a background job.

**Why:** lucos_repos#499 (reviewed and approved this session — diff correct, matched SRE's pinned spec exactly, independently verified line-by-line) raised a background sweep's `RateLimitTransport.MaxWait` from 5m to 30m by mutating it onto a client installed via `conventions.SetHTTPClient`, a package-level global. `src/audit_api.go`'s live `/api/audit/{repo}` endpoint reads the same global with no isolation and no synchronization. 17 minutes after merge, a live request inherited the 30m ceiling mid-sweep and 504'd behind a 60s proxy timeout. Self-diagnosed and filed by SRE as lucos_repos#501 — the function's own doc comment already said "not safe for concurrent use," which would have been the catch available during review, had I read past the diff into the function it mutates.

**How to apply:** a green test suite or a "0 new/resolved findings" audit-dry-run diff only proves the thing that instrument measures is unaffected (here: conventions' own Pass/Fail outcomes) — neither says anything about a *different* caller reading the same mutated global concurrently. When a PR's change is "set X on a shared/global object" (a timeout, rate limit, HTTP client, feature flag, cache), grep for other readers/writers of that global before approving, not just the call site the PR's own diff shows. See [[feedback_robustness_gaps_block]] for the adjacent (but distinct) rule about gaps *in* the code the PR is already touching — this one is about effects *outside* the diff via shared state.
