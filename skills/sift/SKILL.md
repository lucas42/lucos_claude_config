---
name: sift
description: Re-rank Luke's spotted-roles queue in the round — assess each role against his standing filters, place into priority tiers, flag deadlines, and surface drop candidates. A comparative ranking pass over the whole queue, not a per-role operation. Non-gated — execute the re-rank, write it, and report; don't wait for sign-off.
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

- Try `WebFetch` first. For JS-rendered ATSes (Workday, Ashby, Greenhouse, Lever, Pinpoint, Teamtailor) that return thin content, use the JSON endpoints documented in the `/tailor` skill's Step 3 and in `~/.claude/agent-memory/career-advisor/reference_ashby_job_board_api.md` / `reference_pinpoint_ats.md`. (The Thomson Reuters Workday-JSON fetch on 2026-06-03 is the canonical example of resolving a previously-unreadable JD this way.) Note **Phenom** sites (`careers.{company}.com`) return a templated "this job has been filled" message to non-browser fetches and tenant-gate their JSON API — that message is **not** reliable evidence the role is closed.
- **If a JD genuinely can't be fetched, give Luke the URL and ask him to paste the JD contents** — that's the default remedy (he can read a JS-rendered page a fetch can't, and pasting takes one step). Don't block the rest of the pass on it: rank the other roles, and either circle back once he pastes or, if he doesn't, rank that role on title/summary as a fallback (per `feedback_unfetchable_jd_not_a_demotion.md` — a fetch failure is never itself a demotion). Don't settle for a title-only read *without first offering the paste*.

Don't create `orgs/{slug}/notes.md` here — that's a `/tailor` artefact. Keep findings in the pass.

## Step 4: Assess each role against the filters

For every role in the queue (existing + un-triaged), produce a compact read:

- **Recruiter-fronted?** — is the listing posted by a staffing/recruitment agency or a recruiter/talent-partner on behalf of an *unnamed* end-client? **Check this first — it gates how the other signals are read.** Tells: LinkedIn industry tag "Staffing and Recruiting"; poster titled recruiter / "talent partner" / "talent acquisition"; phrasing like "my client", "a {stage}-stage company backed by…", "this and similar roles"; the named "company" is itself a known agency. **The signal usually lives in the *listing*, not the spotted-summary** — a summary can read like a direct-employer post when it isn't (seen 2026-06-16: an entry captured as if its named subject were the AI company; it was a staffing firm fronting an unnamed seed-stage VC-backed startup). So when an entry's summary carries recruiter-pitch flavour or a generic "a company that…" subject, do the light Step 3 fetch to check the poster + industry before trusting its autonomy/comp/culture claims. When fronted + end-client unnamed, those claims describe an employer you **cannot verify** — don't take them at face value (see the Step 5 cap).
- **Autonomy** — favourable / killer / ambiguous, citing the JD phrase that signals it. This dominates — **but only when the employer is known.** A recruiter's autonomy pitch about an unnamed client does not satisfy the floor.
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
- **Recruiter-fronted + unnamed end-client caps the tier — never top.** When Step 4 flags a role as agency/recruiter-fronted with an *unnamed* end-client, its in-listing autonomy / culture pitch is unverifiable and must NOT lift it into the top "apply this week" tier — top tier means max tailoring effort, which shouldn't go to claims about a company you can't even name. Rank these as second/lower-tier **recruiter-ping-first** candidates (the established Lawrence Harvey / Arthur / Few&Far / Opus / La Fosse handling): confirm the end-client + real spec before any `/tailor` pass. A recruiter who *names* the end-client lifts the cap — verify and rank on merit. Disclosed comp stays a real signal; it just can't carry the role to the top alone. (Seen 2026-06-16: a role ranked top-tier on a recruiter's "no layers, no committees / direct founder" pitch about an unnamed seed-stage startup — exactly the claim that can't be verified.)
- **Conversion base-rate gates the top tier, not just the within-tier order.** Per `user_startup_base_rate_fit.md`, a role that triggers the profile-shape headwind — a fast-paced product-led startup prizing end-to-end product ownership that structurally devalues Luke's long-tenure / internal-platform / infra depth (the seed/early-stage "product engineer, full-stack, own everything" shape is the sharpest case) — is a poor *conversion* bet even when autonomy, level and comp all match. Keep it **out of the top tier** on that basis; it can sit second/lower tier for optionality. This is a tier-cap, not an exclusion — don't auto-drop startups, and a strong platform/infra-valuing scale-up doesn't trigger it.
- **Deadline pressure rises within a tier — but only for a genuinely imminent close.** A strong-fit role with a hard close ~**a week or less** away (where the application lead time actually threatens making the cut) is the *first* thing to do in its tier even if a deadline-free role edges it on raw desirability (the Thomson Reuters "apply first — only hard deadline" placement is the pattern). A close that's a **fortnight or more** out is comfortable lead time, **not** urgency — note it for visibility but rank the role purely on merit; don't let it lift the role above deadline-free roles that edge it on fit (per `feedback_deadline_urgency_threshold.md`, Luke 2026-06-15). The deadline is a logistics fact, not a fit signal, until it's imminent — and equally, never *demote* a role for having a comfortably-distant deadline.
- **Respect Luke's deliberate manual positioning** per the prioritised-list rule — if he's hand-placed something, don't silently reorder it; surface the proposed change and let him keep it.
- **An unfetchable JD is NOT a demotion signal.** When a JD can't be fetched (JS-rendered ATS, tenant-gated API, no readable mirror — having genuinely exhausted the fetch routes in Step 3), rank the role on the signal that *is* available (title / summary / employer / level), exactly as for any other thin LinkedIn-only entry. Make "open in a browser to confirm live-status + read the JD" an explicit pre-`/tailor` **action flag**, and state in the entry that the unconfirmed fields are unknown *because of tooling, not merit*. Don't conflate "I can't verify this" with "this ranks lower" (per `feedback_unfetchable_jd_not_a_demotion.md`).
- **Drop candidates**: expired closing dates, confirmed-duplicate-of-already-applied, or roles a filter clearly rules out. Propose these for removal with a one-line reason; don't unilaterally delete unless it's an unambiguous expiry/duplicate.

## Step 6: Decide the re-rank (non-gated — don't wait for sign-off)

**Don't wait on Luke's confirmation to write the re-rank.** Stated 2026-06-15 ("don't wait on my confirmation for future sifts"). Make the tier calls yourself against the filters, write `spotted.md` (Step 7), then report what moved (Step 8). Luke reads the result and adjusts afterwards if he disagrees — that's cheaper than gating every pass on a back-and-forth.

- This was previously a sign-off gate; it no longer is. Don't present a proposal and stop.
- **Genuine judgement calls** (an acceptable-domain-stretch, a comp-floor edge case, displacing a role Luke deliberately hand-placed): make your best call and **flag it clearly in the report** so Luke can veto — don't block the whole pass waiting for an answer. Only use `AskUserQuestion` for a call you genuinely cannot make without his input, and even then rank everything else and write first, leaving just that one flagged. Per `feedback_askuserquestion_phrasing.md` if you do ask.
- Respect Luke's deliberate manual positioning (Step 5) — if a merit re-rank would move a role he hand-placed, surface that in the report rather than burying it.

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
