---
name: github-codesearch-lossy-for-sweeps
description: GitHub org-wide code search is NON-exhaustive — use a fresh origin/main local grep as the authoritative source for any estate sweep
metadata:
  type: reference
---

# GitHub code search is a cross-check, NEVER the authoritative source for an estate sweep

When locking a definitive list against which a plan/decommission/audit will be built (e.g. "every consumer of X across the estate"), **the authoritative sweep is a fresh `git fetch` + `origin/main` checkout local grep across all repos** — NOT GitHub org-wide code search (`search/code?q=...+org:lucas42`).

**Why:** GitHub indexes lazily and silently drops matches. Observed 2026-06-16 (aithne#12 consumer sweep): the same `/data?token` / `auth.l42.eu` query returned a *different incomplete subset on every run*, and missed three repos that demonstrably contained the marker (`lucos_comhra`, `lucos_backups`, `lucos_contacts` — all confirmed by direct read). A decommission plan locked against code-search alone would have orphaned live consumers.

**How to apply:**
- Run BOTH: fresh local grep (authoritative) + code search (cross-check, catches anything not checked out locally).
- Account for marker variants the regex can miss: Python/Django build query strings via `urlencode({'token':...})`/`urlencode({'redirect_uri':...})`, so the literal `data?token` / `authenticate?redirect_uri` is non-contiguous — also grep the env-var forms (`AUTH_ORIGIN`/`AUTH_DOMAIN`) and the bare host.
- Then **read the actual integration in each hit** to classify (verify the consumer, not just the capability) — exclude test-only refs and key-auth-only services that share the host string but aren't in scope.
- Connects to [[feedback_parse_reference_data_never_handbuild]] and [[feedback_grep_and_conclude_anti_pattern]].
