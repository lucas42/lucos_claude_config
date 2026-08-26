---
name: stuck-pr-taxonomy-and-rate
description: Four distinct mechanisms leave a PR or default branch stuck with nothing noticing; measured estate rate and the Dependabot merge-latency distribution that separates stuck from normal in one number
metadata:
  type: project
---

**"Nothing re-runs a red CI pipeline" is one of FOUR mechanisms with the same consequence — and red CI is not the worst two.** Measured 2026-08-26 over loganne 2026-07-29→08-26 (28.7 days) and all 599 Dependabot PRs merged in it, for lucas42/lucos#290.

| mechanism | example | stuck |
|---|---|---|
| red on default branch, alert fires, nobody acts | lucos_repos 07-30; lucos_arachne 08-13 | ~24h each |
| red on a PR branch — monitoring cannot see it (`fetcher_circleci.erl` requests `branch=main`) | lucos_repos#491; lucos_arachne#801/802/803 | 24-39h |
| **no pipeline ever created** — checks never report, nothing is red | lucas42/lucos_aithne#323 | **151.9h** |
| **auto-merge silently disabled** with CI green | lucas42/lucos_repos#485 | **159.3h** |

Seven events, four repos, ~432 cumulative hours. **The two longest are not red-pipeline events at all** (311 of the 432 hours), so any remedy scoped to "re-run red CI" or "show PR-branch CI on the dashboard" misses the worst cases. The common factor is *not progressing*, not *red*. See [[pattern_circleci_400_webhook_drops_pr]] and [[pattern_github_silently_disables_automerge]] for the two non-red mechanisms.

## The one number that separates stuck from normal

Dependabot PR open→merge latency, n=599: **median 5.5 min, p75 8.0, p90 10.9, p95 14.1, p98 19.0 min — then nothing at all until 2 hours**, where 7 PRs sit. Any threshold in the 2-8h band flags exactly the same 7, all genuine, zero false positives.

**How to apply:** for "is this PR actually stuck?", compare against 19 minutes, not against a feeling. And `stale-dependabot-prs` (threshold `staleDependabotThreshold = 48 * time.Hour`, `lucos_repos/src/pr_dashboard.go:56`) keys on the symptom rather than any cause, so it is the only existing check that covers all four mechanisms — but at 48h it catches 2 of 7. I recommended 4-8h on lucas42/lucos#290; not yet decided.

⚠️**Do not count `circleci` alert episodes raw.** 238 episodes in the window; almost all are the 2026-08-17 CircleCI-availability storm (13:50-15:50, whole estate flapping 1-20 min — [[pattern_circleci_unknownsgate_estate_storm]]). Exclude alerts *beginning* in that window and keep only >30 min, which leaves 4 — of which 2 were incidents someone was actively working (lucos_time 08-08 ipv6, lucos_backups 08-17 charset-normalizer) and only 2 were genuine unnoticed reds.

**Resolution path today is a human doing a backlog sweep.** lucos_repos#485 merged 2026-08-17T22:27:35Z and lucos_aithne#323's pipeline was hand-triggered (actor `lucas42`) at 22:34:59Z — eight minutes apart, six days after both got stuck.
