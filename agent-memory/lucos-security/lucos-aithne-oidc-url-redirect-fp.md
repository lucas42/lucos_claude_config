---
name: lucos-aithne-oidc-url-redirect-fp
description: CodeQL go/unvalidated-url-redirection alerts 1 and 2 on lucos_aithne dismissed as false positives (2026-06-10)
metadata:
  type: project
---

## False Positive: go/unvalidated-url-redirection on lucos_aithne (Dismissed 2026-06-10)

Both CodeQL alerts (alert #1 line 154, alert #2 line 238 in `oidc.go`) were dismissed as false positives by `lucos-security[bot]`.

**Why they fire:** CodeQL traces taint from `q.Get("redirect_uri")` → `http.Redirect` and flags it as `go/unvalidated-url-redirection`. The rule doesn't understand that the allowlist check sanitizes the value before either redirect is reachable.

**Why they're false positives:**
- Before both redirect sites, `handleAuthorize` calls `client.HasRedirectURI(redirectURIStr)` at `oidc.go:139`
- `HasRedirectURI` does exact string matching against the server-stored allowlist (`store/oidc.go:42-49`) — no wildcards, no normalisation
- There is no code path through which `redirectURIStr` reaches either redirect without passing the allowlist check
- This is the RFC 6749 §3.1.2.3 / OIDC compliant pattern

**Pattern for future reference:** CodeQL's `go/unvalidated-url-redirection` does not model allowlist-before-sink patterns as sanitizers. Any future OIDC `redirect_uri` redirect that has a pre-check against a registered URI list will produce the same false positive.

Do not re-raise these alerts. If they reappear after a new CodeQL analysis, dismiss again citing `HasRedirectURI` at `store/oidc.go:42-49`.
