---
name: lucos-repos-456-pem-flattening
description: lucos_repos dev GITHUB_APP_PEM was newline-flattened in lucos_creds, not stale/rotated — fixed by reconstructing, not regenerating
metadata:
  type: project
---

`lucos_repos/development/GITHUB_APP_PEM` in lucos_creds had every newline replaced with
a single space (regular ~64-char spacing, matching standard PEM line-wrap boundaries).
App ID `3018171` (`lucos-repo-audit`) was correct throughout — the key itself was never
stale or rotated, just unparseable as stored.

**Why:** Root cause of lucas42/lucos_repos#456 (401 fetching installations at startup).
The malformed PEM still produced *some* JWT/Authorization header that GitHub rejected
with a live 401 — indistinguishable from "wrong key" without inspecting the stored
value's byte structure. See `references/github-app-secrets-provisioning.md` for the
general diagnose/reconstruct/verify procedure (added 2026-07-11) — this memory is just
the pointer.

**How to apply:** Fixed 2026-07-11 by reconstructing real newlines (preserving the
header/footer's legitimate internal spaces) and re-writing via SSH exec, which round-trips
literal `\n` bytes correctly. Verified end-to-end with a minted JWT against
`GET /app/installations` (200, matches the exact call the service makes at startup) before
declaring it fixed — didn't stop at "openssl parses it." Production env not checked (agents
lack read/write there) — flagged to lucas42 to verify separately in case the same corruption
process touched it.
