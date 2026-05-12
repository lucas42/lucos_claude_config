# Triage Procedure

Full triage procedure for the coordinator. Invoked from the coordinator persona and the `/triage` skill.

Companion references (read on demand at the linked points):

- [`triage-reference-data.md`](triage-reference-data.md) — project board IDs, field IDs, board API patterns.
- [`specialist-routing.md`](specialist-routing.md) — when to consult architect / SRE / security / UX.
- [`implementation-assignment.md`](implementation-assignment.md) — choosing the `owner:*` label.
- [`priority-labels.md`](priority-labels.md) — priority assignment and override rules.
- [`audit-finding-handling.md`](audit-finding-handling.md) — special-case closing rules for `audit-finding` issues.

---

## Inline Triage of Agent-Raised Issues

When a teammate agent mentions they have raised a new GitHub issue (e.g. "I raised lucas42/lucos_foo#N"), **triage it immediately** — do not wait for the next scheduled triage run. Apply Steps 1–3 below. Stop short of dispatching the issue unless the user also asks for that.

### Pre-flight: should this issue exist at all?

Before applying any labels, ask whether the issue is a useful addition to the queue or duplicates an existing tracking surface. An issue is **not** useful — and should be challenged with the raiser, not triaged — when ALL of these hold:

- A canonical tracking surface for the finding already exists outside GitHub Issues (Dependabot / CodeQL / secret-scanning alert, monitoring alert, `lucos_repos` convention failure with its own re-raise loop).
- The end-to-end resolution path is fully automated — no human triage, decision, or implementation step between "now" and "fixed" (e.g. Dependabot auto-PRs an upstream patch when it ships, CI runs, auto-merge fires if green, alert closes).
- The body explicitly says "no fix is available yet" / "wait for upstream" — no work for any human or agent until an external precondition lands.

When all three hold, raising a GitHub issue adds coordinator triage overhead and project-board clutter without enabling any action the existing surface wouldn't enable. **Do not apply labels.** SendMessage the raiser explaining why this should not have been raised and asking them to update their standing instructions; close as `not_planned` with a brief comment pointing at the canonical surface; remove from the project board if added. This applies regardless of whether the originating agent is doing routine ops checks or one-off investigation — if their own framing already includes "the auto-PR will appear when upstream patches", that's the signal no separate issue is warranted.

---

## Step 1: Gather All Context

- Read the full issue body carefully.
- **HARD GATE — fetch comments before any assessment.** Make TWO separate API calls (the body endpoint does not include comments; `--jq` on the body alone does not give you comments; the triage script does not include comment text):
  ```bash
  ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager 'repos/lucas42/{repo}/issues/{number}'
  ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager 'repos/lucas42/{repo}/issues/{number}/comments'
  ```
  lucas42 regularly adds decisions, rejections, and revised scope in comments — skipping this step means acting on stale information. **Failure mode:** triaging `lucos_schedule_tracker#47` as `agent-approved` + `owner:lucos-developer` when lucas42 had commented "I propose not doing this" (also `lucos_deploy_orb#124`, `lucos#128` — same shape). **Batch processing does NOT exempt you** — fetch bodies and comments for all issues in parallel; deferring comments to "later" violates this gate.
- **Check reactions on every comment**, especially +1 from `lucas42` — a +1 on an agent's design proposal counts as approval (see "Reactions as approval" below). Do not skip an issue just because the last commenter is `lucos-issue-manager[bot]` — lucas42 may have reacted without writing a new comment.
- Note authoritative decisions from `lucas42` and the current labels.

---

## Step 2: Evaluate the Issue

**Clarity of outcome**: Is it clear what needs to be achieved? Would a developer know what "done" looks like? Flag if the goal is vague, success criteria are missing, or multiple incompatible interpretations are possible.

**Clarity of approach**: Is there any ambiguity in *how* the work should be done? Flag if the implementation path is undefined, competing approaches have no decision, or key decisions have been deferred without acknowledgement.

- **Multiple options with no decision is a hard blocker for `agent-approved`.** An issue listing two or more options without indicating which is NOT ready — the implementer has no idea what to build. **This applies equally when the body doesn't enumerate options but the implementation shape is implicitly open** — e.g. "fix this broken link" where the fix could be implement-the-missing-page, redirect-to-existing, or remove-the-link; or a feature request that names the symptom but leaves the UI/UX shape unspecified. Before approving, ask: *could this be solved in two materially different ways?* If yes, surface the options yourself in a comment, then either (a) consult a specialist for a recommendation (see [`specialist-routing.md`](specialist-routing.md)), post it, re-assess; or (b) if only lucas42 can decide, mark `needs-refining` + `status:awaiting-decision` + `owner:lucas42`. "Any of them would work" does not justify skipping — the implementer needs one agreed direction, not a menu.
- **An agent's recommendation is not a decision.** Re-assess after one arrives: if lucas42 still needs to confirm, mark `needs-refining` + `status:awaiting-decision` + `owner:lucas42`. Only `agent-approved` if no further confirmation is needed.

**Architectural questions**: Flag if the issue touches system design, data modelling, API contracts, or infrastructure in a way that hasn't been resolved.

**Target codebase**: If the issue doesn't yet know which repo the work belongs in, that is an unresolved architectural question — route to the architect with `needs-refining` + `status:needs-design` + `owner:lucos-architect`, even if the rest of the issue is well-specified.

**Cross-issue dependencies**: Check body and comments for prerequisites ("depends on #X", "blocked by #Y", cross-repo `lucas42/other_repo#N`). Unresolved dependency → `agent-approved` + `status:blocked` with the blocker referenced, even if the design is fully agreed.

**Code-context check (issues citing a `TODO` / `FIXME`)**: Fetch the surrounding lines and read the marker in context before approving — don't trust the issue body's interpretation alone. Look for **deferral signals**: "for now", "until X", "placeholder", "future-proofing", "reserved for", "not used yet", "implement when Y arrives", "not currently supported". These indicate the marker *documents* deferred state, not a request for current implementation. The `TODO` prefix is just convention; the surrounding wording carries the intent. If intentionally deferred, close as `not_planned` with an explanatory comment; if ambiguous, message the file's most recent author to confirm first.

---

## Step 3: Take Action

**Triage decisions are made from the ticket — not from out-of-band context.** The implementer only sees the ticket. Before any triage action: (a) anything a teammate sent you alongside the issue (SendMessage summaries, analysis, recommendations) counts only if it is also in the body or a comment — add it first if not; (b) reconcile title and body with comments — if comments contain revised approach, new constraints, refined scope, corrected assumptions, or dependency changes, update title and body to reflect the current understanding.

### If lucas42 has commented on an already-approved issue

The triage discovery surfaces `agent-approved` issues where `lucas42` has commented more recently than the most recent `lucos-issue-manager[bot]` comment. This is the **re-triage trigger** for issues that have moved past initial approval. Re-fetch the body, all comments, and reactions, then decide:

- **Substantive change requested** (revised scope, new blocker, decision lucas42 wants made differently, rethinking the approach) → flip labels back. Remove `agent-approved`; add `needs-refining` + the appropriate status (`status:awaiting-decision` if lucas42 needs to choose between options he's listed; `status:needs-design` if an agent needs to think it through; `status:ideation` if the scope is now genuinely vague again). Re-apply the appropriate `owner:*` label. Update the body to reflect the revised understanding. Reposition on the project board. Then run the rest of Step 3 normally from the new state.

- **Clarification or FYI only** (extra context, answers a question, confirms a detail, but doesn't change what gets built) → post a brief acknowledgement comment, leave labels as-is. **Also: consider whether the clarification belongs in the issue body or title.** The implementer reads the body, not the comment history; baking the clarification into the body (or refining the title) means the next reader doesn't have to scroll through comments to understand the issue. Don't paraphrase — quote or restructure cleanly so the new content integrates with the existing body. If you do edit the body, mention this in your acknowledgement comment ("Updated the body to bake in your clarification about X").

Posting any `lucos-issue-manager[bot]` comment clears the re-triage flag (since the IM is now the most recent commenter), so each lucas42 comment gets exactly one re-triage cycle. **Do not skip the ack comment** — without it, the flag stays set and the same issue keeps reappearing on every triage pass.

This rule applies even when the only "change" appears trivial — read the comment in full before classifying. lucas42 sometimes raises a clarification that looks superficial but reveals a scope assumption worth revisiting.

### If there are agreed changes to make to the issue

Check the changes have been suggested or approved by `lucas42` or by a consulted agent whose input is uncontroversial. Update the issue body with the agreed clarifications/scope changes:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{number} \
    --method PATCH \
    --field body="$(cat <<'ENDBODY'
Updated issue body here with `code` and **markdown**.
ENDBODY
)"
```

If splitting into smaller tickets has been agreed, do that — on the correct repository. Your role only extends to triaging, reviewing, creating and updating issues; code changes are for the implementer.

### If the issue should be closed

1. **STOP — is this an `audit-finding` issue?** If yes, see [`audit-finding-handling.md`](audit-finding-handling.md) before closing.
2. Close the issue directly when you are confident no further work is needed.
3. Leave a brief explanation comment. **If citing another issue as a root-cause tracker or superseding issue, verify it is still open** — a closed issue cannot be tracking a problem. Use `gh-as-agent repos/lucas42/{repo}/issues/{number} --jq '.state'`.
4. Remove any `needs-refining`, `status:*`, `owner:*` labels.
5. **Remove from the project board** — look up the item ID and call `deleteProjectV2Item`. Closed issues should not remain on the board.
6. **Notify interacting agents** via brief FYI SendMessage — raiser, commenters, consulted agents. Include URL, closure reason, lucas42's reasoning if applicable. Especially important when a bot-raised issue is closed as `not_planned` — the originating agent should know so it can adjust future behaviour.

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{number} \
    --method PATCH \
    -f state="closed" \
    -f state_reason="not_planned"
```

Use `state_reason="completed"` if the goal was achieved (e.g. via sub-tickets); `not_planned` if obsolete.

### If the issue is clear and ready to work on

**STOP — specialist consultation checkpoint.** Before applying `agent-approved`, check [`specialist-routing.md`](specialist-routing.md) for the four domains (security, observability, new data models, frontend/UX) that require specialist input first. If any apply, consult now and wait for their comment before continuing here.

1. **Update the issue body to reflect the current agreed scope and approach.** The implementer reads the body, not the comment history; stale body → wrong implementation. Not optional.
2. Add `agent-approved`; remove `needs-refining` if present; remove any `status:*` and review-phase `owner:*` labels.
3. Assign an **implementation owner** label — see [`implementation-assignment.md`](implementation-assignment.md).
4. Assign a **priority** label — see [`priority-labels.md`](priority-labels.md).
5. **Update the project board** — add the issue, set Status/Priority/Owner fields. See [`triage-reference-data.md`](triage-reference-data.md) for field IDs and API patterns.
6. **Position by priority.** Critical/High: `updateProjectV2ItemPosition` with no `afterId` to move to the top. Medium/Low: no repositioning. (Separate API call from setting fields — do not skip for high-priority issues.)
7. Do NOT leave a comment unless there is something genuinely useful to add.
8. **Notify interacting agents** via brief FYI SendMessage with the URL — gives them a chance to update memories. **Do NOT tell the assigned owner to start implementing** — triage approves, it does not dispatch. Word as pure FYI ("FYI: this issue has been approved and assigned to owner:X"), not an instruction.

### If the issue needs input from another agent

When an issue needs input from a specialist, do **not** leave a comment on the issue. SendMessage the agent directly: link to the issue (full URL), explain what input you need and why, and **explicitly say "Post your analysis as a comment on the issue itself (using your own bot identity), then message me back with the comment URL when done."** Do NOT phrase as "post your answer back here" or "report back to me" — that leads to the analysis arriving in your inbox and forcing wrong-attribution paraphrasing on the ticket.

**CHECKPOINT — never post an agent's analysis on the ticket on their behalf.** When their analysis arrives via SendMessage, the *agent* posts it on the issue, not you. If you find yourself drafting a comment that begins "Consulted lucos-X" or "Per lucos-X's analysis" or quoting/paraphrasing their content, STOP. Send the agent back to post under their own bot identity, with the URL when done. Three reasons: (1) attribution matters — readers need to see whose analysis it is from the avatar/login, not infer it; (2) paraphrasing flattens nuance; (3) it collapses technical analysis and triage coordination into one voice.

Your role is the triage coordination layer only: ask for input, label the issue, update the board, and optionally leave a short triage-decision comment that *references* the agent's comment (e.g. "Marking awaiting-decision after consulting lucos-X above").

Once the agent messages back, re-read the issue — fetch **all** comments and check reactions, especially +1 from lucas42 (they may have replied or reacted in the interim; a +1 on the agent's comment counts as approval). Then re-assess:

- lucas42 approval (comment or +1) → act on it.
- Issue clear and ready → `agent-approved`.
- Needs input from a *different* agent → message that agent next (one at a time, so each sees prior comments).
- Needs lucas42 input → `needs-refining` + `status:awaiting-decision` + `owner:lucas42`.
- Going in circles (>3 rounds of agent consultation on the same issue) → stop and route to lucas42.

### If the issue needs input from lucas42 (or cannot be resolved by agents)

1. Add `needs-refining`; remove `agent-approved` if present.
2. Apply a **status** label and an **owner** label (full table in the coordinator persona).
3. Add a comment explaining what input is needed from lucas42.
4. Assign a **priority** label — see [`priority-labels.md`](priority-labels.md). Refinement work also needs prioritisation.
5. **Update the project board** — add, set fields, position by priority (Critical/High to the top). See [`triage-reference-data.md`](triage-reference-data.md).

### If the issue is a topic you own (workflow, process, labels)

Handle it yourself — you are the domain expert. Post your recommendation as a comment, then:

- if your comment fully resolves the issue → `agent-approved` + `owner:lucos-issue-manager`
- if your comment surfaces questions only lucas42 can decide → `needs-refining` + `status:awaiting-decision` + `owner:lucas42`
- if your comment surfaces questions another specialist should weigh in on → `needs-refining` + `status:needs-design` + `owner:lucos-<specialist>`

Update the project board accordingly.

**Owning the issue does not let you defer scope or design decisions to implementation time.** If your triage comment contains "I'll resolve during planning", "open implementation considerations to be worked through when I pick this up", "captured for future reference", "Need to decide: X or Y", "the interesting question is", or any other phrasing that lists open choices that aren't yours to make unilaterally with confidence — those questions must be routed at triage time, not carried forward as `agent-approved` work. The cost of getting this wrong is stopping mid-dispatch to ask the question that should have been asked at triage, which wastes a full cycle and signals an incomplete triage to lucas42.

Triage either closes the open questions or routes them. There is no third option of "approve it and decide later."

---

## Central Label Controller

**The coordinator is the sole agent responsible for managing labels across all lucos issues.** No other agent adds, removes, or changes labels. A single point of label control means a consistent, auditable view of each issue's status.

For issues labelled with `owner:` and `needs-refining` from a previous session, detect completed agent work: if an agent's comment is the most recent activity, treat it as their completed input — transition to `agent-approved` if uncontroversial, or `status:awaiting-decision` + `owner:lucas42` if it needs sign-off.

**Reactions as approval.** A +1 reaction from `lucas42` on a comment is approval of the recommendations in that comment. Most relevant when an agent has posted a design proposal: a +1 on a design proposal or implementation plan transitions the issue to `agent-approved` (assuming no other blocking questions); a +1 on a comment listing multiple options with a recommendation counts as agreement with the recommended option.
