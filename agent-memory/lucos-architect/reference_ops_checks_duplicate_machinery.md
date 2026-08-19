---
name: ops-checks-duplicate-machinery
description: Three of SRE's seven ops checks duplicate machinery already running in the estate; plus the parallel-barrier reason ops-check reallocation between personas cannot help
metadata:
  type: reference
---

Consulted 2026-08-19 on whether SRE's ops-check load should be reallocated to an idle persona. Findings below verified by reading code that day.

## The /routine barrier — and the makespan error I made about it

`~/.claude/skills/routine/SKILL.md`: Phase 1 dispatches code-reviewer, security, sysadmin and SRE **concurrently**; Phase 2 (triage) is gated on **all four** completing. SRE is therefore the critical path.

**I initially claimed rebalancing between personas was "a no-op by construction". That is FALSE — see [[feedback_absolute_then_hedge_detector]].** makespan = max(legs), not sum, so rebalancing an *unequal* set strictly reduces it. Measured 2026-08-19: SRE 37m36s (still running), security ~2-3m, sysadmin ~3m, code-reviewer ~5m. Moving 15m off SRE to any lighter leg takes makespan 37→~22. Rebalancing is a real lever with a bounded payoff — rank it **third, behind delete and automate**, never rule it out.

Two bounds worth quoting when anyone cites a `total/N` figure: transferred work is **not conserved** (the recipient pays context-load, and hands back to SRE for diagnosis on a finding), and ops-check work is **not infinitely divisible** (Check 1's root-cause mandate doesn't split at all).

**Which checks actually cost makespan.** Every-run is Checks 1, 2, 3 (sre-ops-checks.md:39) plus Check 4 as the rotating one (:223). Monthly is 5, 6, 7 (:265) — and they're usually skipped. So **deleting 5/6/7 buys ~zero makespan**; do it for signal-honesty, not workload. The every-run judgement-dense checks dominate — which means automation has *less* headroom against the measured problem than the duplication findings below suggest. The makespan-relevant automation targets are the **detection halves of Checks 2 and 3** (both every-run, both pure functions over Loganne events).

Free win requiring no automation: the barrier's stated rationale is "issues raised are available for triage in this pass". That justifies only checks which can surface something needing *this* pass's triage. Monthly checks filing P3s, and Check 3 (which files a PR), do not need to gate triage at all — though on a typical run this is a signal/clarity win rather than a time one.

## Checks that duplicate running machinery

- **SRE Check 7 (external dependency reachability)** — every item already monitored, three of four *better*:
  - Docker Hub: `lucos_docker_mirror/info/app.py:_check_upstream` GETs `https://registry-1.docker.io/v2/`, accepts 200/401 — the identical probe with the identical expected status, exposed via `/_info` so polled continuously.
  - CircleCI: `lucos_monitoring/src/fetcher_circleci.erl` polls it every 60s per repo, with a deliberate third-party `unknown` state + unknowns gate.
  - GitHub API: exercised by `lucos_repos` sweeps (`c4GitHubClient`, src/c4.go:23).
  - Let's Encrypt: `fetcher_info.erl:checkTlsExpiry` fails at <20 days to expiry; LE certs are 90-day, so ~10+ days lead time on a broken renewal.
- **SRE Check 5 (CI status)** — `fetcher_circleci.erl` covers every system + CI component in configy every 60s. Residual: the manual check enumerates the whole GitHub org, so repos absent from configy are unwatched — a set-difference `lucos_repos` already reconciles for C4.
- **SRE Check 6 (`/_info` schema)** — `fetcher_info.erl:parseInfo` already throws on missing/non-string `system` and non-map `checks`/`metrics`; `validateChecks` degrades a malformed entry to `ok:false` + `techDetail`. A structurally broken `/_info` already fails Check 1. Residual (non-structural quality fields) belongs in `lucos_repos/src/c4.go:203 probeInfoEndpoint`, which already GETs every configy system's `/_info`.

## Durable principles from this

- **Measure the consequence, not the dependency.** A cert-expiry check beats an ACME-reachability probe: it catches rate limits, auth failures and a renewal cron that isn't running. Generalises to any external-dependency monitoring proposal.
- **An external dependency's health check belongs in the `/_info` of the system that consumes it** — that's the estate's existing model, and it gives attribution and blast radius for free.
- **A check whose instructions embed a 40-line script is already a program**, being run by the most expensive interpreter available.
- **Detection/diagnosis splits are sound machinery↔agent, unsound agent↔agent.** Handoff cost means the split only pays when detection is expensive and findings rare — which is exactly the profile machinery serves best. So automation dominates the split on every axis.
- Exception: where detection *is* judgement (container log review — "is this stack trace worth caring about" needs a model of normal), it doesn't decompose. `grep -c traceback` is a prefilter, not a detector.
- **The asset is the probe discipline, not the check.** Moving a check without its accumulated "here is how this probe lies to you" notes makes the traps recur; duplicating the notes makes them drift. Argues against relocating ops checks between personas generally.
- **A monthly manual check that is usually skipped and never fails provides the feeling of coverage, not coverage** — and that is worse than nothing, because it retires the concern. Automate it or delete it; keeping it manual is the worst of the three.

Related: [[reference_info_endpoint_observability_inversion]], [[reference_convention_catalogue]], [[feedback_prefer_self_healing_finding_over_silent_suppression]].
