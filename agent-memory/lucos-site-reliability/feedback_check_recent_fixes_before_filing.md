---
name: Check recent fixes before filing flap-investigation issues
description: Before raising an issue about a recurring monitoring flap, search for recently-merged PRs / closed issues in the same repo that may already have addressed it
type: feedback
---

Before filing an issue about a recurring monitoring flap on system X, check whether a fix has already shipped in the last 24-48 hours that you don't yet have evidence about.

**Why:** alert data has lag — pre-fix alerts persist in the lookback window for as long as the lookback covers, even after the fix has gone live. If you only look at "is the alert pattern present in the last N days?" you'll see flaps from before the fix and conclude the fix didn't happen. The fix may already exist and just hasn't had time to clear the historical alerts from your view.

Bit me 2026-05-06 on `lucas42/lucos_eolas#234`: I raised a fetch-info-flap-investigation issue at 09:50Z. Lucas had already merged PR #231 (the fix for the same issue, #228) at 11:43Z the previous day — fix had been live for 22 hours. Zero alerts post-fix; all 18 alerts in my lookback predated the deploy.

**How to apply:** Before filing any "recurring flap on X" issue, do at least these three checks against the affected repo:

1. `gh-as-agent repos/lucas42/{repo}/issues?state=closed&sort=updated&direction=desc&per_page=10` — has a related issue closed in the last 7 days?
2. `git log origin/main --since="3 days ago" --oneline` in the local sandbox — any commit messages mention `_info`, the affected check name, latency, performance, etc.?
3. Cross-tabulate the most recent alert timestamp in your data against the most recent deploy of the affected system. If recent deploys post-date the most recent alert, the fix may already be in.

If any of these three turn up a candidate fix, **always include the pre-fix vs post-fix split in the issue body** — even if you decide the issue is still worth filing. Saves the next reader from doing the same investigation.
