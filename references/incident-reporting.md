# Incident Reporting

This document defines the process for writing an incident report for a specific resolved critical incident. Incident reports live in `docs/incidents/` in the `lucos` repo.

Use this process when you have identified a critical issue that needs a report -- whether during ops checks (Check 2: Incident Report Coverage) or when asked to write a report ad-hoc.

> **STOP — read the completion checklist before you start, not after.** Incident-report work uses **a single draft PR that stays open through the whole incident** and is only finalised at the end. This is what lets the report accumulate the full picture — verification results, then the team's folded-in responses — in *one* PR instead of a wave of post-merge amendment PRs. It is delivered when *all five* items below are true, not when the PR is opened:
>
> 1. Report written following `docs/incidents/TEMPLATE.md`
> 2. **Draft** PR opened early and kept open — every amendment (verification results, folded-in team responses, late follow-up links) goes on the same branch. Do NOT mark ready or merge mid-incident.
> 3. Follow-up issues filed and linked in the Follow-up Actions table
> 4. Team notified **on the draft**, and their responses folded into the report
> 5. Only once the incident is resolved AND the team responses have settled: mark the PR **ready**, drive the code-reviewer review loop to approval (per `pr-review-loop.md`), and **merge**
>
> The full checklist with checkbox syntax is at the bottom of this file. It is duplicated here at the top because every previous false-completion of this workflow has been caused by reading down to Step 2 and stopping. The draft-stays-open lifecycle (items 2→5) is the load-bearing change: keeping the PR in draft is precisely what avoids the ship-then-amend churn.

## Extend an existing report, or write a new one?

Before writing a new report, check whether the incident you are about to document is actually a *continuation* of an existing one. The rule:

- **Ongoing impact** → extend the existing report. If the user-visible impact (e.g. "no backups are running", "service is down", "data is stale") has not yet been resolved, and a new failure is just the next chapter of the same story, append to the existing report rather than creating a new one. Add a new section to the timeline, document the second failure mode, and update the resolution / follow-up sections.
- **Fresh impact** → write a new report. If the previous incident was fully resolved (impact ended, service restored to normal) and a *new* problem has since started, that is a separate incident even if the symptoms or affected systems look similar.

When in doubt, ask the team-lead before creating a fresh report — it is far easier to fold information into an existing report than to merge two later.

## Open the draft PR early and keep it open — don't sit idle, don't merge early

When verifying an incident's resolution takes meaningful time — multi-hour cron reruns, soak windows, estate-wide deploy propagation, post-failure data backfills, etc. — start the report and open its **draft** PR in parallel with the verification. Two principles:

- **Don't sit idle before drafting.** Almost everything that goes into the report (root cause, code-site references, fix description, timeline up to the verification trigger, the analysis sections) is already known once the fix is shipped.
- **Open early as a draft, but don't *merge* until the end.** Durability of state-in-git matters more than a TBD-free first commit — pushed commits survive a context loss, uncommitted disk material does not. But because the report keeps growing (verification results, then the team's folded-in responses), the PR stays a **draft** until the incident is fully wrapped, so every addition is one push to one branch rather than a new PR each time.

The pattern:

1. Once the fix is shipped and verification is in flight, start drafting immediately and **open a draft PR** as soon as the draft is coherent. List the outstanding TBDs in the PR body so a cold reader (e.g. you in a future session) can pick up the work.
2. Leave verification-result sections as clearly-marked TBDs. Examples:
   - In the timeline: `2026-04-28 HH:MM | Rerun completes — TBD pending result`
   - In the header table: `Duration | … — TBD pending verification`
   - In the summary: `Verified end-to-end with rerun — TBD pending rerun completion`
3. As verification completes and team responses arrive, **fill in the TBDs and fold in the responses by pushing commits to the same draft branch.** Because the PR is a draft it cannot auto-merge out from under you — there is no "fresh PR because it already merged" case to handle mid-incident, which is the whole point.
4. If verification surfaces a further failure mode (the incident isn't actually resolved yet), update the draft to reflect the new chapter of the story. An explicit `TBD pending result` line is not a claim of success, so leaving it in place while waiting is fine — but once the result is known, do not retain a stale TBD.
5. **Only finalise at the very end** (Step 4 below): once the incident is resolved and the team's responses have settled, mark the PR ready, drive the review loop to approval, and merge.

The one exception: if something material develops *after* the final merge, the report is still amendable — open a fresh branch off main and a follow-up PR referencing the original. This should be the rare case, not the norm; the draft-stays-open lifecycle exists precisely so nearly everything lands before the single merge.

This rule applies equally to fresh reports and to extending an existing one.

## Propagate factual corrections through every narrative section

When a reviewer (lucas42, team-lead, code-reviewer, or any other source) supplies a factual correction during the drafting or review loop — especially one about *framing* (e.g. "this wasn't routine, it was X"; "the cause wasn't Y, it was Z"; "the trigger wasn't discretionary, it was instructed by W") — apply it to **every** narrative section that touches the corrected fact, not just the section the reviewer pointed at.

Why: the closest match to the reviewer's quote is rarely the only place where the original framing appeared. The Summary, Timeline (especially pre-incident rows), Analysis stages, "What Was Tried That Didn't Work," Sensitive Findings, and the PR description are all narrative surfaces. Most readers skim the Summary; a Summary that contradicts a deeper section is worse than either alone, because it creates visible incoherence and signals carelessness.

The pattern:

1. Re-read the reviewer's correction in full and identify the **fact** being corrected, not just the surface wording.
2. `grep` the file for the **original framing** — the wording you used before the correction — and any synonyms you might have varied (e.g. "routine," "maintenance," "scheduled," "hygiene," "automatic," "background," "incidental"). Don't rely on memory of where you wrote what; let `grep` find every occurrence.
3. For each match, decide whether the correction applies. If yes, rewrite that sentence/row to match the corrected framing. Update both the prose and any structured fields (timeline rows, header table) consistently.
4. **Re-read the Summary explicitly after the pass.** Even after a thorough grep, the Summary often retains residual phrasing (different word, same framing) that the grep didn't catch. The Summary is the most-read section; getting it consistent is the highest-leverage thing.
5. Push a single commit with the propagation pass and reference the corrector in the commit message ("per lucas42's correction" / "per team-lead's correction").
6. When reporting back to the corrector, **list every section you updated**, not just "I applied your correction" — that lets the corrector verify the propagation was complete without reading the diff.

This is independent of whether the original framing was yours or inherited from upstream sources (issue body, PR description, prior agent's notes). The propagation pass is about the report's coherence, not assigning blame.

## Verify the root cause actually caused *this* failure — don't ship a hypothesis as the cause

A root cause is **established** only when you have confirmed it actually produced the observed failure — not merely that it is a plausible mechanism that *could* have. Naming an unverified mechanism as "the root cause" is worse than writing "cause not yet confirmed": it ends the investigation, sends fix effort at the wrong target, and reads as authoritative when it isn't.

Before writing any mechanism into the Root Cause section as *the* cause, confirm the causal link by at least one of:

- **Reproduction** — you (or a controlled test) reproduced the observed failure through the hypothesised path. A controlled repro is the right tool; do not skip it for convenience, or because a fix "would help regardless," or because mutating test data feels heavier than reasoning. If a repro is the only way to confirm and it's safe, run it (coordinate with the team-lead on any production-touching repro) — declining the one step that would confirm the cause, then shipping the unconfirmed cause anyway, is the trap.
- **Direct evidence the failing request took that path** — e.g. a logged error / stack frame from the *actual* failing request showing the hypothesised code path; not just "that path exists and is slow."

**Stop and treat your cause as UNCONFIRMED if any of these hold:**

- The diagnosis depends on a fact you don't actually have ("it must be because the user was setting X" — did you confirm they were?).
- The thing your hypothesis blames isn't present in the affected record (you blame predicate/field P, but the affected item has no P).
- The timing or other evidence doesn't cleanly fit, and you're rationalising the mismatch rather than resolving it.
- The cause is inferred chiefly from "a recent change touched a related area." Recency is a prompt to investigate, not proof of causation — a plausible recent-change story must not crowd out checking simpler or pre-existing/latent causes.

If you cannot verify before the report must ship, **write the Root Cause section with the mechanism explicitly labelled a leading hypothesis (not confirmed), state exactly what verification is outstanding, and keep the Resolution UNRESOLVED** until confirmed. A confident-but-unverified narrative — however well-reasoned — is the failure mode this section exists to prevent.

> Lesson from 2026-05-29 (lucos_media_metadata_api save-502): the team published a composer/producer eolas-resolution root cause built entirely from "recent migration + that save path makes a synchronous eolas call," across three report PRs, without ever reproducing the actual failing save. The real cause was unrelated and latent — an Album-typed value selected in the `about` field, whose API rejection was neither surfaced to the UI nor logged. Every red flag above was live: the affected track had no composer/producer tag, the 502 timing didn't fit the hypothesised path, a controlled repro was offered and declined, and the whole diagnosis hinged on an unconfirmed assumption about what the user was editing.

## Step 1: Write the incident report

Given a closed critical issue that needs a report:

1. **Gather context**: Read the full issue body, all comments, and any linked PRs (check for `Closes #N` / `Fixes #N` references and PR cross-references in the timeline). Piece together the timeline, root cause, and resolution from the available information.

2. **Write the report**: Create a new file following the template at `docs/incidents/TEMPLATE.md`. The file naming convention is `YYYY-MM-DD-short-description.md`, where the date is the date of the incident (not today's date). Use lowercase words separated by hyphens for the description.

3. **Fill in the template** using information gathered from the issue and its linked PRs:
   - **Summary**: What happened, what the impact was, how it was resolved
   - **Timeline**: Reconstruct from issue timestamps, comments, and PR merge times
   - **Root cause**: Technical explanation drawn from the issue discussion
   - **Resolution**: The specific fix applied, referencing PRs/commits
   - **Follow-up actions**: Link to any open issues raised as a result. If any follow-up actions do not yet have a tracked issue, raise one and link it in the table. **The SRE writing the incident report is the designated owner of filing all follow-up issues.** Other agents must not independently file follow-up issues from the same incident — this causes duplicates. If another agent identifies a follow-up action, they should message the SRE or the issue manager rather than creating the issue themselves.
   - If information for a section is not available from the issue or its comments, say so explicitly (e.g. "Timeline details not available from the issue discussion") rather than inventing details

4. **Reference the source issue**: Include a link to the original critical issue near the top of the report (e.g. in the summary or as a metadata field) so there is a clear audit trail.

5. **Use fully-qualified cross-repo references.** Because incident reports live in the `lucos` repo, bare `#N` references resolve to `lucos` issues -- not the repo where the incident occurred. Always use the `lucas42/repo_name#N` format for issue and PR references (e.g. `lucas42/lucos_contacts#42`, not `#42`). This is the general rule from CLAUDE.md but is especially easy to get wrong in incident reports, where nearly every reference points to a different repo. **Each `#N` instance auto-links independently against the host repo — qualifying once in a paragraph does not carry context to later instances.** Concretely: a Follow-up Actions row whose first mention is `lucas42/lucos_claude_config#97` and whose later sentence reads "the reference doc in #100" will still mis-link that bare `#100` to `lucos#100` (a real but unrelated issue), not to `lucos_claude_config#100`. Qualify every instance, or rewrite as prose ("PR #100 in `lucos_claude_config`") when repeated qualification would be visually noisy.

## Step 2: Open a draft PR (and keep it open through the incident)

Create a branch, commit the report, and open a **draft** PR on the `lucos` repo — early, as soon as the draft is coherent. Keep it in draft while the report accumulates verification results and the team's folded-in responses.

```bash
cd ~/sandboxes/lucos
git checkout -b incident-report-{short-description}
~/sandboxes/lucos_agent/git-as-agent --app lucos-site-reliability \
    add docs/incidents/{filename}.md
~/sandboxes/lucos_agent/git-as-agent --app lucos-site-reliability \
    commit -m "Add incident report for {short description}

Refs lucas42/{repo}#{number}"
~/sandboxes/lucos_agent/git-as-agent --app lucos-site-reliability \
    push -u origin incident-report-{short-description}
```

Then open the PR as a **draft** with `create-pr` (always use `create-pr`, never `gh-as-agent … pulls` directly — it handles the supervised-repo reviewer step). Write the body to a unique tempfile first:

```bash
~/sandboxes/lucos_agent/create-pr --app lucos-site-reliability --repo lucos \
    --title "Add incident report: {short title}" \
    --body-file /tmp/pr_body_incident_{slug}.md \
    --head incident-report-{short-description} --base main --draft
```

Put the source/originating issue(s) and the list of outstanding TBDs in the body so a cold reader (you, in a future session) can pick up the work. If multiple critical issues need reports, include them all in one PR with a commit per report.

**Do NOT mark this PR ready or drive it to merge yet.** Every amendment through the incident — verification results, folded-in team responses, late follow-up links — goes on this same branch (Step 3). It is finalised only in Step 4. A draft PR cannot auto-merge, which is exactly why it can stay open and absorb everything in one place.

## Step 3: Notify the team on the draft, and fold in their responses

Once the incident is resolved and the draft report is coherent (verification TBDs filled or clearly marked pending), notify every other teammate — pointing them at the **draft** report so they can review it for their domain and surface any follow-ups *before* it's finalised. This is the step that earns the draft-stays-open lifecycle: responses get folded into the same PR rather than chased through separate amendment PRs after merge.

**There is no broadcast mechanism in SendMessage.** Setting `to: "broadcast"` puts the message into a phantom inbox no agent reads — it does not multiplex. The only structured message types are `shutdown_request`, `shutdown_response`, and `plan_approval_response`. To reach the whole team, send **individual SendMessage calls**, one per teammate. You can issue all of them in a single response (parallel tool calls).

Recipients (excluding yourself):

- lucos-architect
- lucos-code-reviewer
- lucos-developer
- lucos-security
- lucos-system-administrator
- lucos-ux

Suggested content (same for each recipient):

```
Draft incident report for your review: docs/incidents/{filename}.md (PR lucas42/lucos#{pr})
Source/originating issue(s): lucas42/{repo}#{number}
Summary: {one-line summary of what happened and the root cause}
Lessons: {bullet list of the load-bearing lessons most likely to affect future work}
Read the draft at: https://github.com/lucas42/lucos/blob/{branch}/docs/incidents/{filename}.md

This is still a draft — I'm finalising once responses settle. If it highlights a follow-up action in your domain, message lucos-site-reliability to coordinate before filing any issue (I own incident follow-ups, to avoid duplicates) — see "Receiving incident notifications" below.
```

As responses arrive:

- Fold domain input, factual corrections, and architecture/security-style observations into the report by pushing commits to the draft branch (apply "Propagate factual corrections through every narrative section" above).
- When a teammate raises a follow-up in their domain, coordinate per "Receiving incident notifications" below, then link the resulting issue in the Follow-up Actions table.

**Don't block forever on silence.** "Responses have settled" means the active threads have gone quiet, not that every teammate has acknowledged. Give a reasonable window, fold in what lands, and proceed to Step 4. Because the team engaged with the draft here, no separate post-merge "lessons broadcast" round is needed.

## Step 4: Finalise — mark ready, review, merge

Only once the incident is resolved AND the team's responses have settled (Step 3) AND every follow-up issue is filed and linked in the Follow-up Actions table (Step 1.3):

1. **Tick the outstanding-items checkboxes in the PR body** (the TBD list from Step 2) now that each is done, *then* **mark the draft PR ready for review** (GraphQL `markPullRequestReadyForReview` — see `references/github-workflow.md` for the mutation and node-id lookup). The code-reviewer verifies those checkboxes on unsupervised repos and an unchecked gate can hold the approval, so don't leave them unticked even when the body text demonstrably satisfies them.
2. **Drive the code-reviewer review loop to approval and merge**, per `pr-review-loop.md` — message `lucos-code-reviewer` and don't stop at "marked ready". On `lucos` (unsupervised) reviewer approval triggers auto-merge.

After merge the report is final. If something material develops *afterwards*, the report is still amendable via a fresh follow-up PR referencing the original — but that's the rare exception; the draft-stays-open lifecycle exists so nearly everything lands before this single merge.

## Receiving incident notifications

When you receive a notification about a published incident report, read it for lessons relevant to your domain. If the notification or the report itself highlights a follow-up action you want tracked, **do not file a GitHub issue directly.** The SRE is the designated owner of filing all incident follow-up issues (Step 1.3 above). Filing independently causes duplicates.

**Message `lucos-site-reliability` first.** There are two valid cases:

- **Direct incident follow-up** — the action is a corrective measure specifically prompted by this incident (e.g. adding a check that catches this class of failure in future). The SRE should file it, citing the incident. Send the SRE your framing and let them file.

- **Pre-existing latent concern ("Reading B")** — the incident merely surfaced a concern that would have been worth addressing regardless. Under Reading B, the concern legitimately belongs to the domain expert's identity, not the SRE's. The domain expert may file it — but only after confirming with the SRE that Reading B applies, so the SRE can decide whether to link it in the Follow-up Actions table.

The coordination step is what matters. Whether the SRE or another persona ultimately files the issue is secondary: **the goal is exactly one issue per concern, with the incident report cross-referenced in the body.**

## Completion checklist

The incident report is delivered when ALL of the following are true. Reporting back to the dispatcher before all five are true is incomplete; do not substitute an outcomes-style "Done" summary that omits any step.

- [ ] Report written following `docs/incidents/TEMPLATE.md` (Step 1)
- [ ] Draft PR opened early and kept open; all amendments on the same branch, not merged mid-incident (Step 2)
- [ ] Follow-up issues filed and linked in the report's Follow-up Actions table (Step 1, item 3)
- [ ] Team notified on the draft and their responses folded in (Step 3 — six individual messages, not one "broadcast")
- [ ] PR marked ready, reviewed, and merged once the incident is resolved and responses have settled (Step 4)

### Mandatory completion-report format

Before reporting back to the dispatcher (team-lead or user) that the incident report is delivered, **the completion message must restate each of the five checklist items verbatim, each annotated `done` or `not done`**. This is a forcing function: composing the message exposes any item that isn't actually true.

Example completion-report fragment:

> **Incident report completion checklist:**
> - [x] Report written following `docs/incidents/TEMPLATE.md` — done (`docs/incidents/2026-05-18-…md`)
> - [x] Draft PR opened early and kept open — done (`lucas42/lucos#161`, draft from HH:MMZ; verification + responses folded on the same branch)
> - [x] Follow-up issues filed and linked — done (`lucas42/lucos_arachne#544` in Follow-up Actions table)
> - [x] Team notified on the draft and responses folded in — done (architect, code-reviewer, developer, security, system-administrator, ux — six messages)
> - [x] PR marked ready, reviewed, and merged — done (`lucas42/lucos#161`, merged HH:MMZ)

If any item is `not done`, the completion report is premature; **do not send it**. Continue the work (fold in responses, finalise the PR) and report back only once all five are `done`. A partial-progress update is fine and welcome — but it must clearly say "in progress" and list which items remain, not "done" / "no outstanding actions".

> **Note on the draft lifecycle vs. fast incidents.** For a small, fully-resolved incident with no pending verification and no likely cross-domain follow-ups, the draft window can be brief — open draft, notify, and if nothing comes back, finalise in the same session. The draft step is not bureaucratic overhead; it's insurance that the *common* case (verification results and team responses arriving after the report's first draft) lands in one PR instead of several. Don't skip the draft just because an incident *looks* simple — the seinn/backups incidents looked simple too and still drew follow-up amendments.
