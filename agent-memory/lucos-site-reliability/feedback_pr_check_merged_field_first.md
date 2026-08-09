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

**Base rate, measured 2026-08-09 — and it does NOT weaken the rule.** I content-diffed every branch on `lucos`: 121 besides `main`, 115 fully merged, 6 ahead, of which 5 had no open PR. **All five were superseded drafts — zero genuine instances of the lost-push mechanism across ~4 months of history.** So the hazard is *situational*, not long-standing: the trigger is a burst of rapid follow-up PRs on one artifact (3 PRs on one report inside 20 minutes), not everyday PR work. Keep the freeze rule at full strength — its justification is the two instances that day, not a base rate — and note team-lead deliberately kept this figure **out** of `pr-review-loop.md`, because "this has never happened before" sitting beside a rule is an invitation to ignore it. It lives here as calibration, not as an argument.

⚠️ **Do not audit branches by `ahead_by` — diff the content.** `ahead_by: 1` persists forever when content shipped via cherry-pick. And when asking "does file X exist in `main`?", **ask the same of the branch**: a file *deleted on the branch* reads identically to a file *lost from `main`*. That inverse-question control is the only thing that stopped me publishing "an entire incident report is unpublished" — it wasn't; the branch had deleted it during a consolidation.

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
