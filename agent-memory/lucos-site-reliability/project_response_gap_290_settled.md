---
name: project-response-gap-290-settled
description: lucas42/lucos#290 — the alert→action response gap is DOCUMENTED and its broad remedy DECLINED on cost, not unqueued; the narrow remedy is Ready and owned by me. Escalate only on three named triggers.
metadata:
  type: project
---

**Do not re-raise the "alert fired, nobody acted for N hours" gap as a new finding.** It is lucas42/lucos#290, and the position is settled — not unexamined.

**What was decided (2026-08-26, verified against the thread on 2026-09-08):**
- **Scope narrowed to** the `staleDependabotThreshold` constant in `lucos_repos`, 48h → ~6h, **and nothing else**.
- **A CI re-run robot and extending monitoring to PR branches were both explicitly ruled out**, with reasons. The `branch=main` scoping of `fetcher_circleci.erl` was assessed as *correct* and stays.
- The decline was made **after** my own frequency analysis in that thread (2026-07-29→2026-08-26, 28.7 days): **7 events across 4 repos, ~432 cumulative hours stuck**. So it is a priced proportionality call, not an oversight.

**Why this matters more than "already ticketed":** *documented but declined* is a **more final** answer than *nobody has looked yet*. Re-putting a settled call to lucas42 each time an already-quantified rate produces another instance spends his attention on arithmetic already done. (team-lead's own first framing — "already ticketed, nothing needed" — was too glib and they corrected it; the accurate version is this one.)

⚠️ **One correction to that correction, verified on the live board 2026-09-08:** the narrow remedy is *not* unqueued. **#290 is Status = Ready, Priority = Low, Owner = `lucos-site-reliability`** — i.e. mine to implement when dispatched. "Nothing is queued" is true of the *broad* remedy only.

⚠️ **The narrowed remedy does NOT cover the default-branch shape — verified from source 2026-09-08.** `lucos_repos/src/pr_dashboard.go:248` fetches `pulls?state=open` only, and L287 gates on `pr.CreatedAt`, so `stale-dependabot-prs` can only see a **still-open** PR. The 09-08 event was red on `main` *after* both PRs merged ⇒ **no threshold value would have fired**. This was deliberate, not an oversight: my own analysis headed the two sections *"For the six PR-level events: one constant"* and *"For the two default-branch events: I'd leave it, for now"*. The constant addresses **everything except gap 1** (gap 1 = red on default branch; gap 2 = red off it; plus 3 non-CI mechanisms). Gap 1 now carries 3 of the recorded occurrences.

⚠️ **Both revisit conditions are DORMANT, not armed — they are gated on a dispatch nothing schedules.** Mine ("if the threshold change lands and default-branch reds are still sitting in a month") and team-lead's trigger 3 both presuppose the constant ships; it is Ready/Low and unstarted, so neither clock has started. **Treat triggers 1 and 2 as the only live ones.** This is the shape where a revisit condition becomes a way of never revisiting.

⚠️ **I measured the WRONG POPULATION and got the right answer by luck (2026-09-08).** Trigger 1 names an **estate-wide** rate (~7 events/29d); I measured **gap 1 only** and declared it not met. Real estate-wide figure, 08-26→09-08 (13d, **all 271 merged Dependabot PRs, paginated in full — the API's default 100-of-271 is an order-biased sample**): 4 PRs open >6h + 1 gap-1 event = **5 events in 13d = 11.0 per 28.7d vs 7.0** — up ~57%. Still judged not-met (expected ~4.1, observed 5; unremarkable at n=5, and 3 of the 5 arrived in one morning's burst), but that is a small-numbers **judgement**, not a comfortable margin. **Escalate if the next window is similarly elevated — two consecutive elevated windows.** Free corroboration of method: **p98 merge latency 19.1 min now vs 19 min in the 08-26 analysis**, independent data.

**Rate check to reuse (gap 1 only):** 2 events in 28.7d at analysis (07-30 `lucos_repos`, 08-13 `lucos_arachne`) → 3 events in 40d incl. 09-08 `lucos_creds` = **2.15 per 28.7d vs 2.00. Unchanged.** So trigger 1 is NOT met; don't mistake a third occurrence for a rising rate.

**Escalate only if one of these is met** (testable, so it isn't a judgement call each run):
1. A **materially higher sustained rate** than ~7 per 29 days.
2. An occurrence whose cost is **qualitatively worse than a delayed deploy** — data loss, a real outage, or a stale credential store *actually serving*.
3. **The narrowed remedy ships and the gap persists anyway.**

No agreement from team-lead is needed to escalate on any of these.

**Occurrences so far:** 2026-08-17, two `lucos_repos` events, 2026-09-08 (`lucos_creds`, 15h10m, from lucas42/lucos_creds#555). Record new ones on #290 as data points; don't open anything new.

**Damage-narrowing that must survive citation:** the 09-08 event did **not** leave the estate on stale credentials — the preceding commit deployed v1.3.146 on schedule and only a later `ui/package-lock.json` bump went undeployed. See [[feedback_verify_check_claim_against_underlying_store]].
