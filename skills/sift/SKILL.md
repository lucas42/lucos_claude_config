---
name: sift
description: Re-rank Luke's spotted-roles queue in the round — assess each role against his standing filters, place into priority tiers, flag deadlines, and surface drop candidates. A comparative ranking pass over the whole queue, not a per-role operation. Interactive — proposes the re-rank for sign-off before writing.
disable-model-invocation: false
---

Triage skill for `lukeblaney_cv_tailored/applications/spotted.md`. Ranking is **comparative** — a role's tier is meaningful only relative to the rest of the queue — so this is a single pass over the whole list "in the round", never a per-isolated-role operation. (Fast-capture of individual roles is `/spotted`; deep per-role research + form-probe is `/tailor`. This skill sits between them: it decides *which* roles are worth a `/tailor` pass and in what order.)

Optional argument: a scope hint (e.g. `/sift just the un-triaged ones`). Default with no argument is a full re-rank of the entire queue, which naturally folds in any un-triaged captures sitting below the marker.

## Step 0: Routing

This is career-advisor work — uses the career-advisor GitHub identity for commits, follows career-advisor memory conventions.

- **If you are the career-advisor agent**: follow the steps below directly.
- **If you are any other agent**: send a message to the `career-advisor` teammate (`"sift {optional scope}"`) and wait for the result. Do not perform the work yourself.

## Step 1: Load the filters and standing rules

These define how Luke ranks roles. Read before assessing anything — don't rank from memory of them, the files are authoritative and change over time:

**The filters (in priority order):**
- `~/.claude/agent-memory/career-advisor/user_autonomy_as_floor.md` — **the primary fit signal**, ahead of title / comp / domain. Includes the strong/killer/ambiguous JD-language lists and the RTO-mandate-as-autonomy-proxy read.
- `~/.claude/agent-memory/career-advisor/user_work_enjoyment_signals.md` — enjoyment-fit (architect-around-problems vs low-level bottleneck-tuning) as a ranking *weight* atop the autonomy floor.
- `~/.claude/agent-memory/career-advisor/user_startup_base_rate_fit.md` — fast-paced product-led startups devalue Luke's long-tenure / internal-platform profile; weight down on conversion even when other signals match.
- `~/.claude/agent-memory/career-advisor/project_funnel_state_2026_05.md` — pointer to the private strategy doc holding the comp-floor-with-promotion-path, Central-London-or-remote, aspirational-pattern, and ethics filters, plus runway context. Read the pointed-to doc.

**Skills-inventory triage signals** (tech that should NOT pull a role up, and genuine gaps that pull it down):
- `~/.claude/agent-memory/career-advisor/user_skills_inventory.md` — note especially the "JD-triage signal" lines: Kubernetes, Kafka, and data-platform/data-engineering emphasis must NOT be weighted as positive fit; named-compliance-framework / OT-ICS / VMware-Azure-years gates are genuine gaps.
- `~/.claude/agent-memory/career-advisor/user_role_framing.md` — level-positioning, so a role's seniority match is judged correctly.

**Standing rules for the queue itself:**
- `~/.claude/agent-memory/career-advisor/feedback_spotted_is_prioritised_list.md` — order carries priority; respect Luke's manual positioning where he's set it deliberately.
- `~/.claude/agent-memory/career-advisor/feedback_tracker_scope_action_not_completeness.md` — the queue serves active work, not completeness; dropping a poor-fit role is fine and expected.
- `~/.claude/agent-memory/career-advisor/feedback_borderline_ethical_deferral.md` — don't pre-emptively drop borderline-ethical companies; flag once and keep them in the queue.
- `~/.claude/agent-memory/career-advisor/project_applications_tracker.md` — tracker conventions (this skill only touches `spotted.md`, never `in-progress.md` / `closed.md`).

## Step 2: Read the current queue

Read `~/sandboxes/lukeblaney_cv_tailored/applications/spotted.md` in full. Identify:

- The current tier structure and the order within each tier.
- **Un-triaged captures** sitting below the `New captures land below…` marker — these are the priority input; they have no tier yet.
- Existing entries whose standing may have drifted: a **closing date now passed**, a "watch / confirm" caveat that a JD fetch could now resolve, or a role that's gone stale.

## Step 3: Gather just enough signal to rank

For any role where the tier call needs more than the title + summary already in the entry, fetch the JD. **This is a light fetch for ranking only — not the deep form-probe `/tailor` does.** Enough to read seniority, IC-vs-management, autonomy language, stack, location/remote, comp, and closing date.

- Try `WebFetch` first. For JS-rendered ATSes (Workday, Ashby, Greenhouse, Lever, Pinpoint, Teamtailor) that return thin content, use the JSON endpoints documented in the `/tailor` skill's Step 3 and in `~/.claude/agent-memory/career-advisor/reference_ashby_job_board_api.md` / `reference_pinpoint_ats.md`. (The Thomson Reuters Workday-JSON fetch on 2026-06-03 is the canonical example of resolving a previously-unreadable JD this way.)
- If a JD genuinely can't be fetched, note it and rank on what's known — don't block the whole pass on one role; flag it for Luke to open manually.

Don't create `orgs/{slug}/notes.md` here — that's a `/tailor` artefact. Keep findings in the pass.

## Step 4: Assess each role against the filters

For every role in the queue (existing + un-triaged), produce a compact read:

- **Autonomy** — favourable / killer / ambiguous, citing the JD phrase that signals it. This dominates.
- **Enjoyment-fit** — architect-around-problems (up) vs bottleneck-tuning / data-plane ops (down).
- **Level** — match / stretch / below-target against `user_role_framing.md`.
- **Comp** — vs the floor (with promotion-path latitude); "undisclosed" is neutral, not a negative.
- **Location** — Central-London-or-remote satisfied? Hard RTO mandate = weak autonomy-negative.
- **Skills signal** — any deadweight-tech-that-shouldn't-count or genuine-gap gate.
- **Startup base-rate** — hyper-growth product-led startup discount where it applies.
- **Deadline** — closing date and days remaining; expired = drop candidate.
- **Ethics** — flag once if borderline; don't drop pre-emptively.

## Step 5: Rank in the round

Sort the field into the tiers (current headings: `Top priority — apply this week` / `Second tier — apply this month if capacity allows` / `Lower priority — kept for optionality`). Apply these ordering rules:

- **Autonomy first, then enjoyment-fit, then level/comp/domain** — the established weighting.
- **Deadline pressure rises within a tier.** A strong-fit role with a hard near-term close is the *first* thing to do in its tier even if a deadline-free role edges it on raw desirability (the Thomson Reuters "apply first — only hard deadline" placement is the pattern).
- **Respect Luke's deliberate manual positioning** per the prioritised-list rule — if he's hand-placed something, don't silently reorder it; surface the proposed change and let him keep it.
- **An unfetchable JD is NOT a demotion signal.** When a JD can't be fetched (JS-rendered ATS, tenant-gated API, no readable mirror — having genuinely exhausted the fetch routes in Step 3), rank the role on the signal that *is* available (title / summary / employer / level), exactly as for any other thin LinkedIn-only entry. Make "open in a browser to confirm live-status + read the JD" an explicit pre-`/tailor` **action flag**, and state in the entry that the unconfirmed fields are unknown *because of tooling, not merit*. Don't conflate "I can't verify this" with "this ranks lower" (per `feedback_unfetchable_jd_not_a_demotion.md`).
- **Drop candidates**: expired closing dates, confirmed-duplicate-of-already-applied, or roles a filter clearly rules out. Propose these for removal with a one-line reason; don't unilaterally delete unless it's an unambiguous expiry/duplicate.

## Step 6: Propose the re-rank for sign-off (gate)

Ranking is judgement-heavy and Luke has strong, specific views — **do not rewrite `spotted.md` before he signs off.** Present a concise proposal:

- The **tier each role lands in**, and specifically **what moved** (promotions, demotions, drops) with a one-line reason each.
- Any role where the call genuinely needs Luke's judgement (an acceptable-domain-stretch question, a comp-floor edge case) — ask it directly rather than guessing. Use `AskUserQuestion` with clear "tick to approve" semantics per `feedback_askuserquestion_phrasing.md`.
- Don't recap roles whose position didn't change beyond a one-line "unchanged: …" summary.

Get sign-off (with any adjustments) before writing.

## Step 7: Write and commit

Rewrite `spotted.md` into the signed-off order. Keep each entry's existing content; where the pass added a tier-rationale, fold it into the entry (a `**Why {tier}:**` line, matching the style already in the file). Remove the `un-triaged` marker line from any capture that now has a tier; leave the marker itself in place for future captures. For dropped roles, remove the entry (add a brief `<!-- Removed {date}: … -->` tombstone only when the reason is non-obvious and future-useful, e.g. duplicate-of-applied — not for routine "decided against").

```bash
cd ~/sandboxes/lukeblaney_cv_tailored && \
  git add applications/spotted.md && \
  ~/sandboxes/lucos_agent/git-as-agent --app career-advisor commit -m "sift: re-rank spotted queue ({date})" && \
  git push origin main
```

Commit messages may name companies freely — `lukeblaney_cv_tailored` is the private repo.

## Step 8: Report

Brief summary back to Luke: how many roles assessed, the headline moves (what's now top-of-queue, what got promoted/demoted/dropped), and any role left flagged because its JD couldn't be fetched. Don't recap the whole list — he can read the file.

## What this skill does NOT do

- **No per-org `notes.md`, no form-probe, no artefact drafting** — those are `/tailor`.
- **No pipeline-state changes** — moving a role to `in-progress.md` / `closed.md` happens when Luke reports a submission or outcome, not here. This skill only ever edits `spotted.md`.
- **No new captures** — adding a role from a URL is `/spotted`. If Luke pastes a new URL mid-sift, capture it via the `/spotted` flow first, then include it in the ranking.
