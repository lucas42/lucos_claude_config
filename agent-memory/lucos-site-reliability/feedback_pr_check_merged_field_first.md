---
name: feedback-pr-check-merged-field-first
description: "PR state fetches must include merged/merged_at — and never answer 'did my change land?' from the PR at all: merged PRs freeze, so a later push is invisible. Verify against origin/main by content."
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

**⚠️ The bigger trap (2026-08-08, twice in one hour): a merged PR's state FREEZES, so no PR endpoint can show a commit pushed afterwards.** `commits`, `head.sha`, `changed_files` and `reviews` all stop at the merge — they return a confident, coherent, *wrong* picture. On `lucos` (unsupervised) approval auto-merges within minutes, so pushing a follow-on commit to a branch whose review you requested loses it **silently**: git reports success, the PR page looks fine, the commit is not in `main`, and there is no error. Both team-lead and I checked `/pulls/N/commits` + `head.sha` and concluded "it landed"; only the **live branch tip** + `compare` showed otherwise (`lucos-code-reviewer` did it right).

**Never answer "did my change land?" from the PR. Answer it from `main`, by content:**
```bash
git fetch -q origin
git log --oneline origin/main..origin/<branch>          # must be empty
git show origin/main:<file> | grep -c '<text you added>' # + a positive control
```
`ahead_by` is also unreliable **in the other direction**: a branch whose content shipped via a cherry-pick reports `ahead_by: 1` forever and reads as unmerged work. **Diff the content, not the commit graph** — that's what makes a stale branch safe to delete (record the tip SHA first; branches restore from it).

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
