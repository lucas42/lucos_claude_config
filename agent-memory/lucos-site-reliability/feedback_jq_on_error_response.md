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

**Update 2026-08-06 — the same trap on a 200: a MISSING KEY also yields `null`.** `--jq '.some_field'` returns `null` whether the field is present-and-null or absent entirely, so you cannot tell "configured as null" from "not configured" from "the API never sends this to App tokens". Use `has("field")` to disambiguate:

```bash
gh-as-agent --app lucos-site-reliability repos/lucas42/$r/branches/main/protection \
  --jq '{has: (has("required_pull_request_reviews")), val: .required_pull_request_reviews}'
```

Bit me on lucos_worlds/main: I read `required_pull_request_reviews: null`, asserted to three teammates that main has **no** review requirement and that "dismiss stale reviews" concerns were therefore moot. The key was in fact **absent** (`has(...) == false`) — a jq artefact, not a value.

**And absence needs a positive control before you interpret it.** I checked 7 protected repos and the key is missing on *all* of them, so I have no instance of it ever being present — meaning I cannot distinguish "GitHub omits it when unconfigured" (the documented reading) from "App tokens never receive it". Until I see it present *somewhere*, the honest statement is "no evidence of a review requirement", not "there is none". A uniformly-negative sample is not evidence of absence; it's an untested instrument. Related: [[feedback_verify_check_claim_against_underlying_store]].

**Update 2026-07-13 — the error stdout is NOT reliably `null`.** On the orb-npm-publisher sweep, `gh-as-agent ... --jq '.content'` on a 404 emitted the **raw error JSON** (`{"message":"Not Found",...,"status":"404"}`, exit 1), NOT `null`. So the failure mode is worse than "always null": stdout on error may be `null` OR the full error object, and either way it's non-empty and can slip past a naive filter — e.g. grepping it for a token happens to not match, so it looks like a legit-but-empty config. **Most robust pattern for a fetch-and-inspect loop:** don't `--jq` a field; fetch the raw response and classify explicitly — `grep -q '"type": *"file"'` = real file, `grep -q '"status": *"404"'` = genuinely absent, else = a real error to surface. This gave 0 silent errors across 98 repos (62 have config, 36 don't) where the earlier `--jq`-guard had misclassified all 98 as "present".
