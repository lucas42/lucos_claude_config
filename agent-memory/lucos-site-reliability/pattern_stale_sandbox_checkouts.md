---
name: stale-sandbox-checkouts
description: ~/sandboxes/* checkouts lie two ways — months stale AND parked on a feature branch; always name origin/main explicitly (git pull does NOT fix the branch case) before claiming a file/repo state
metadata:
  type: feedback
---

`~/sandboxes/<repo>` checkouts are NOT current. They can lag `origin/main` by months and even contain repos that are no longer deployed (e.g. `lucos_comhra` — not in monitoring/configy/DNS).

**Why:** During the 2026-06-30 aithne post-migration SRE review, my LOCAL `lucos_photos/api/app/auth.py` still had `AUTH_DOMAIN="https://auth.l42.eu"` (the decommissioned service) with per-request remote introspection and no JWKS. I nearly raised SIX false "broken browser auth" incidents (photos, mmm, creds, loganne, notes, comhra). Live HTTP probes proved every deployed service redirects to `aithne.l42.eu/auth/login` — fully migrated — and `git show origin/main:.../auth.py` had a `_ResilientJWKSClient` (last-known-good). Local was ~2 months behind (last commit 2026-04-23).

**How to apply:** Before raising ANY code-derived finding (especially migration/decom "X still uses the old thing" claims):
1. `git -C ~/sandboxes/<repo> fetch origin` then read `git show origin/main:<path>` or `git grep <pat> origin/main` — never trust the working tree.
2. **Live-probe the runtime** — `curl -s -o /dev/null -w "%{http_code} %{redirect_url}" -H "Accept: text/html" <url>`. Runtime behaviour is authoritative over any source read. (This is the [[reference_loganne_read_self_verify]] / runtime-reachability discipline applied to code review.)
3. Cross-check undeployed-vs-deployed via monitoring/configy/DNS before treating a repo as live.

The hedging rule bit me here: I reasoned from stale code as if it were live state. Evidence (live probe) > inference (local source).

## The second failure mode: parked on a feature branch (`git pull` does NOT save you)

Staleness is only half of it. The checkout may sit on **a branch you created in an earlier session**, and `git pull --ff-only` cheerfully refreshes *that* branch — so a subsequent `ls`/`grep` reads the wrong tree while looking completely healthy.

**Why:** 2026-08-09 ops checks, Check 3. `~/sandboxes/lucos` was on my own `incident-report-home-link-packet-loss` branch. `git pull --ff-only` + `ls docs/incidents/` + `grep -ril 'pool overlap\|fd00:2\|subnet collision'` → **NO MATCH**, so I concluded the 2026-08-08 `lucos_time` outage had no incident report and started writing one. It had been **merged to `main` at 00:04:17Z** (PR lucas42/lucos#281). I caught it only because lucas42/lucos#282's body happened to cite the report's path.

The tell that did *not* fire: the `grep` still returned hits from **older** incident files, so it looked like a working probe returning a real negative — a per-item miss, not a blank result ([[feedback_treat_empty_tool_output_as_unknown]] doesn't cover this; nothing was empty).

**How to apply:** never let a bare path stand in for a ref.
- `git -C <repo> fetch -q origin main`, then `git ls-tree --name-only origin/main <dir>/` and `git grep -il <pat> origin/main -- <dir>/`. Naming the ref makes the branch state irrelevant.
- Before concluding an artifact is **missing**, check the PR list too — an unmerged **draft** PR is the expected mid-incident state for an incident report and still means "don't write a second one".
- Generalises past git: for any "does X exist in A?" question, ask the same of a known-present B as a control.
