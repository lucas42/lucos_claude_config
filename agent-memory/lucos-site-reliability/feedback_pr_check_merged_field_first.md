---
name: feedback-pr-check-merged-field-first
description: When fetching PR state to decide on action, always include `merged`/`merged_at` in the query — post-merge `mergeStateStatus` is misleadingly UNKNOWN
metadata:
  type: feedback
---

When re-fetching a PR's state to decide whether to act on it, **always pull `merged`/`merged_at` alongside `state`/`mergeable`/`mergeStateStatus`**. A merged PR has:

- `state: closed`
- `merged: true`
- `merged_at: <timestamp>`
- `mergeStateStatus: UNKNOWN` (GraphQL — surprisingly NULL-ish post-merge)
- `mergeable: UNKNOWN` (GraphQL) or `null` (REST)
- `autoMergeRequest: null`

If you only inspect the second cluster of fields, a merged PR looks *very* similar to an open PR whose state is still being computed by GitHub. Same `UNKNOWN`/`null` values, same superficially-stuck appearance. Acting on this false negative led me to close + attempt-reopen an already-merged PR.

**How to apply**: every PR-state fetch made before a write action (close, reopen, merge, label change, auto-merge toggle) must include `merged`, `merged_at`, and `state` at minimum. A safe canonical query:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-site-reliability \
  repos/lucas42/<repo>/pulls/<N> \
  --jq '{state, merged, merged_at, merged_by: .merged_by.login, mergeable_state}'
```

Or in GraphQL:

```graphql
pullRequest(number: N) { state merged mergedAt mergeable mergeStateStatus }
```

**Why**: bit me 2026-05-26 on the stuck-PR investigation for `lucos_media_seinn#483`. While investigating, I also probed `lucos_loganne#498` "for the same issue" and based my close+reopen action on `mergeable: UNKNOWN` — not realising lucas42 had merged #498 37 minutes earlier. The close was a no-op (already closed), but the attempted reopen failed and left a recreated orphan branch I had to delete. No real damage, but noisy on the PR thread.

This is also a specific case of [[feedback_verify_before_propagating]] — the broader rule about verifying identifiers/state before acting on them.
