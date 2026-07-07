---
name: natural-experiment-before-fix-ticket
description: Test a suspected systemic-failure hypothesis with a live, unraced natural experiment before filing/keeping a fix ticket for it
metadata:
  type: feedback
---

When a historical PR/log pattern looks like a systemic failure (e.g. "Dependabot has never once bumped this dependency"), check whether a cheap live experiment can falsify the hypothesis before proposing or keeping a fix ticket for it.

**Why:** Investigating lucas42/lucos_aithne#283 (Dependabot apparently never bumping the `lucos_auth_scopes` Docker pin, 4-for-4 over a month), I filed a drift-detector ticket (lucas42/lucos_repos#450) on the assumption this was a silent, indefinite-staleness bug. A Dependabot job log (pulled by lucas42 from GitHub's Insights UI, not available via API) revealed the daily check ran at a fixed ~14:44 UTC and that every prior "manual" bump had landed a few hours *before* that day's scheduled check — a human always won the race because new scopes are typically needed urgently. Since nobody had raced the very next scheduled run yet, I predicted (and reported the prediction before the fact) that it would succeed unassisted — and it did: PR opened, merged, and deployed within 3 minutes, no config change. Both #283 and #450 closed as no-defect/not-planned.

**How to apply:** Before proposing a durable fix for an apparent "X never happens automatically" pattern, ask whether a live retry with no manual intervention is available and cheap to observe (a scheduled job, a retry-able check). If so, let it run and check the result — it's stronger evidence than any number of historical PR-log comparisons, and it can turn a suspected bug into "no fix needed" before any code/config change ships. Pairs with [[feedback_read_before_theorising]] — reading the source explains the mechanism, but only a live run proves whether it currently works.
