---
name: feedback-jq-on-error-response
description: Existence checks via gh-as-agent + --jq must use --silent + $? exit code, not jq output, because jq on a 404 JSON body silently outputs `null`
metadata:
  type: feedback
---

When using `gh-as-agent ... --jq '.field'` to check whether a resource exists, **do NOT test the captured stdout**. If the API returns a 404 with body `{"message":"Not Found", ...}`, `--jq '.field'` outputs the literal string `null` (jq's default for a missing field). `[ -n "null" ]` evaluates to true, so every 404 looks like a hit.

**Why:** GitHub's REST API returns a JSON error body on 404. `gh api`'s exit code IS 1 in that case, but if you suppress stderr (`2>/dev/null`) and only test stdout via `[ -n "$x" ]`, you lose the signal entirely.

**How to apply:** for any "does this file/resource exist" loop using `gh-as-agent`, use `--silent` and check `$?`:

```bash
gh-as-agent --app lucos-site-reliability "repos/lucas42/$repo/contents/path/to/file.yml" --silent 2>/dev/null
status=$?
if [ "$status" = "0" ]; then ... existence-true branch ... fi
```

Not:

```bash
# WRONG — `null` from jq on 404 is non-empty
content=$(gh-as-agent --app lucos-site-reliability "repos/.../path.yml" --jq '.name' 2>/dev/null)
if [ -n "$content" ]; then ... fi
```

Bit me 2026-05-21 on the estate-wide stale-auto-merge-workflow sweep: first pass categorised all 65 repos as having both files (because the 404 responses all output `null` from `--jq '.name'`). Caught on a sanity-check against `lukeblaney_cv` (a known no-stale-file repo) returning the same "exists" answer.
