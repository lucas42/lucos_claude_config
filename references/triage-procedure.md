# Triage Procedure

Full triage procedure for the coordinator. Invoked from the coordinator persona and the `/triage` skill.

---

## Step 1: Gather All Context

- Read the full issue body carefully.
- **HARD GATE — fetch comments before any assessment.** Call the comments endpoint for every issue, no exceptions. Do not assess, label, or close an issue until you have read its comments. The triage script does not include comment text. This rule exists because lucas42 regularly adds decisions, rejections, and revised scope in comments — if you skip this step you will act on stale information. **Concrete failure mode:** triaging `lucos_schedule_tracker#47` as `agent-approved` + `owner:lucos-developer` when lucas42 had already commented "I propose not doing this."
- **Check reactions on every comment** — especially +1 reactions from `lucas42`. A +1 on an agent's design proposal counts as approval (see "Reactions as approval" below). When fetching comments, always include reactions data in your assessment. Do not skip an issue just because the last commenter is `lucos-issue-manager[bot]` — lucas42 may have reacted to a comment without writing a new one.
- Note any updates, decisions, or clarifications made by `lucas42` — these are authoritative.
- Note the current labels on the issue.

---

## Step 2: Evaluate the Issue

**Clarity of outcome**: Is it clear what needs to be achieved? Would a developer know what "done" looks like?
- Flag if: the goal is vague, success criteria are missing, or multiple incompatible interpretations are possible.

**Clarity of approach**: Is there any ambiguity in *how* the work should be done?
- Flag if: the implementation path is undefined where it matters, there are competing approaches without a decision, or key technical decisions have been deferred without acknowledgement.

**Architectural questions**: Are there significant architectural decisions that need to be made before work can begin?
- Flag if: the issue touches on system design, data modelling, API contracts, or infrastructure in a way that hasn't been resolved.

**Target codebase**: Is it clear which repository the implementation belongs in?
- Flag if: the issue doesn't yet know which repo or codebase the work should happen in, or includes a step to choose or decide on a location. "Where should this live?" is an unresolved architectural question — route to the architect with `needs-refining` + `status:needs-design` + `owner:lucos-architect`, even if the rest of the issue is well-specified.

**Cross-issue dependencies**: Does this issue depend on another issue being completed first?
- Check whether the issue body or comments reference other issues as prerequisites (e.g. "depends on #X", "blocked by #Y", or sequencing like "step 1 must be done before step 2"). This includes cross-repo references (e.g. `lucas42/other_repo#N`).
- If the issue has unresolved dependencies, it should be marked `agent-approved` + `status:blocked` with the blocking issue referenced in the body or a comment — even if the design is fully agreed and the issue is otherwise ready. An issue that cannot be started yet is blocked, regardless of how well-specified it is.

---

## Step 3: Take Action

**Always reconcile the issue title and body with its comments.** Before taking any triage action, check whether the comments contain information that materially changes the issue — e.g. revised approach, new constraints, discovered prior art, refined scope, corrected assumptions, or dependency changes. If they do, update both the issue title and body to reflect the current understanding. The title should accurately describe the work as currently scoped — not the original proposal if the scope has changed. The implementing agent reads the title and body, not the full comment history — if they're stale, the agent will implement the wrong thing.

**If there are agreed changes that need to be made to the issue:**
1. Check that the changes have been suggested by, or approved by, user `lucas42` or by a consulted agent whose input is uncontroversial
2. Update the issue body with any clarifications, improvements or alterations agreed on in the comments:
   ```bash
   ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{number} \
       --method PATCH \
       --field body="$(cat <<'ENDBODY'
   Updated issue body here with `code` and **markdown**.
   ENDBODY
   )"
   ```
3. If it's been agreed to split the issue into smaller tickets, do that. Ensure the new issues are created on the correct repository.
4. Remember: your role only extends to triaging, reviewing, creating and updating the github issues. Any changes to the code should be left for whoever picks up the ticket to do, not you.

**If the issue should be closed** (e.g. superseded by other issues, split into sub-tickets that replace it, or agreed in discussion to be obsolete/unnecessary):
1. **STOP — is this an `audit-finding` issue?** If yes, see `~/.claude/references/audit-finding-handling.md` before closing.
2. Close the issue directly — you have authority to do this when you are confident no further work is needed.
3. Leave a brief comment explaining why the issue is being closed (e.g. "Closing: this has been superseded by #X and #Y"). **If you reference another issue as a root cause tracker or a superseding issue, verify it is still open before citing it.** A closed issue cannot be tracking a problem — citing one is a factual error that sends readers to a dead end. Use `gh-as-agent repos/lucas42/{repo}/issues/{number} --jq '.state'` to check.
4. Remove any `needs-refining`, `status:*`, and `owner:*` labels before closing, as they are no longer relevant.
5. **Remove the issue from the project board.** Look up the item ID for this issue on the "lucOS Issue Prioritisation" project board and delete it using `deleteProjectV2Item`. Closed issues should not remain on the board.
6. **Notify agents who interacted with the issue.** Send a brief FYI message (via SendMessage) to every agent who raised, commented on, or was consulted about the issue during its lifecycle. Include the issue URL, the closure reason, and any relevant context (e.g. lucas42's reasoning for rejecting a finding). This is especially important when an issue raised by a bot persona (e.g. `lucos-security[bot]`) is closed as not_planned — the originating agent should know why so it can adjust future behaviour.

To close an issue:
```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{number} \
    --method PATCH \
    -f state="closed" \
    -f state_reason="not_planned"
```

Use `state_reason="completed"` if the issue's goal was achieved (e.g. via sub-tickets or other work), or `state_reason="not_planned"` if the issue is being discarded as obsolete or unnecessary.

**If the issue is clear and ready to work on:**

**STOP — specialist consultation checkpoint.** Before applying `agent-approved`, ask:
- Does this issue touch **authentication, authorisation, data protection, secret management, credentials, or other security topics**? → consult `lucos-security`.
- Does it touch **monitoring, logging, observability, reliability, or incident management**? → consult `lucos-site-reliability`.
- Will it make a **significant change to user journeys on a frontend system** — new pages, navigation changes, form flows, interaction patterns, error states, or anything that meaningfully affects how users move through a system? → if the ticket is dominantly frontend/UX work, assign `owner:lucos-ux` directly as implementer (no consultation step needed); if the ticket also has substantial backend work, keep `owner:lucos-developer` and consult `lucos-ux` for triage input.

If yes to any of the above, you MUST consult the relevant specialist (see "Specialist Follow-up Routing" below) BEFORE applying `agent-approved`. Do not skip this step just because the proposed change "looks like a security improvement" or "is only in CI" — specialist consultation is about getting expert eyes on the change. **Concrete trip-wires** that mean you must consult security: anything that changes authentication mode (trust ↔ password, mTLS, OAuth flow), anything that adds/removes/rotates credentials or env vars holding secrets, anything touching `auth`/`login`/`session` code paths, anything that changes how a database accepts connections, anything that changes who can read or write a resource. If unsure, consult the relevant specialist — the cost of an unnecessary consult is small; the cost of a missed one is unbounded. **This rule was extended after marking `lucos_eolas#164` (CI trust auth → password auth) `agent-approved` without consulting security.** Once the specialist has weighed in, return to this step and continue.

1. Add the label `agent-approved` to the issue.
2. Remove the label `needs-refining` if it is present.
3. Remove any `status:*` and review-phase `owner:*` labels.
4. Assign an **implementation owner** label (see "Implementation Assignment" below).
5. Assign a **priority** label (see "Priority Labels" below).
6. **Update the project board** — add the issue, set Status/Priority/Owner fields. Read `~/.claude/references/triage-reference-data.md` for field IDs and API patterns.
7. **Position the item on the board by priority.** Critical/High: call `updateProjectV2ItemPosition` with no `afterId` to move to the top. Medium/Low: no repositioning needed. **This is a separate API call from setting fields — do not skip it for high-priority issues.**
8. Do NOT leave a comment unless there is something genuinely useful to add.
9. **Notify agents who interacted with the issue.** Send a brief FYI message (via SendMessage) to every agent who commented on or was consulted about the issue during its lifecycle. Include the issue URL and mention it has been approved — this gives them an opportunity to read the conclusions and update their memories. No response is needed from them. **Do NOT tell the assigned owner to start implementing — triage approves issues, it does not dispatch work. Implementation is triggered separately via `/next` or `/dispatch`. The notification should be worded as an informational FYI only (e.g. "FYI: this issue has been approved and assigned to owner:X"), not as an instruction to start work.**

**If the issue needs input from another agent:**

When an issue needs refinement from an agent (architect, SRE, security, sysadmin, developer, or code-reviewer), do **not** leave a comment on the issue. Instead, message the agent directly as a teammate using SendMessage. In your message:
- Link to the issue (full GitHub URL)
- Explain what input you need from them and why
- Ask them to post a comment on the issue (or add a reaction to an existing comment) with their input, then message you back when done

Once the agent messages you back, re-read the issue — fetch **all** comments (not just the agent's new one) and **check reactions on every comment** (especially +1 from lucas42). lucas42 may have replied or reacted in the time between the agent posting and you re-reading. A +1 reaction on the agent's comment counts as approval of its recommendations. Then re-assess:
- If lucas42 has replied with approval, or added a +1 reaction to the agent's comment, act on that
- If the issue is now clear and ready, mark it `agent-approved`
- If it needs input from a *different* agent, message that agent next (one at a time, so each sees prior comments)
- If it needs input from lucas42, mark it `needs-refining` + `status:awaiting-decision` + `owner:lucas42`
- If it's going in circles between agents (more than 3 rounds of agent consultation on the same issue), stop and route to lucas42

This inline consultation replaces the old pattern of labelling with `owner:` and waiting for a separate review phase. The goal is to resolve as much as possible in a single triage pass.

**If the issue needs input from lucas42 (or cannot be resolved by agents):**
1. Add the label `needs-refining` to the issue.
2. Remove the label `agent-approved` if it is present.
3. Apply a **status label** and an **owner label** (see the coordinator persona for the full table).
4. Add a comment explaining what input is needed from lucas42.
5. Assign a **priority** label (see "Priority Labels" below) so that refinement work is also prioritised.
6. **Update the project board** — add the issue, set Status/Priority/Owner fields, and position by priority (Critical/High to the top). Read `~/.claude/references/triage-reference-data.md` for field IDs and API patterns.

**If the issue needs refinement but is a topic you own (workflow, process, labels):**
1. Handle it yourself — you are the domain expert. Post your recommendation as a comment.
2. If your recommendation resolves the issue, mark it `agent-approved`.
3. If it needs lucas42's sign-off, mark it `needs-refining` + `status:awaiting-decision` + `owner:lucas42`.
4. **Update the project board** accordingly.

---

## Specialist Follow-up Routing

Some issues need review from a specialist agent **after** the primary agent has given their input, but **before** the issue is marked `agent-approved`. This applies to two domains: observability/reliability (SRE) and security.

#### SRE follow-up on observability issues

When an issue touches **monitoring, logging, observability, reliability, or incident management** topics, consult the primary agent first (e.g. architect for design, sysadmin for infrastructure), then also consult `lucos-site-reliability` before approving. Do these sequentially so the SRE sees the primary agent's comment.

#### Security follow-up on security-sensitive issues

When an issue touches **authentication, authorisation, data protection, secret management, or other security topics**, consult the primary agent first, then also consult `lucos-security` before approving. Do these sequentially so the security agent sees the primary agent's comment.

#### UX follow-up on mixed frontend+backend changes

When an issue is owned by `lucos-developer` (i.e. the backend work is substantial enough that developer is the right implementer) but will **also** make a significant change to user journeys on a frontend system — new pages, navigation changes, form flows, interaction patterns, error states, or copywriting on user-facing surfaces — consult `lucos-ux` for triage input before approving.

**Pure frontend/UX work should NOT be routed through this path.** If the ticket is dominantly a frontend/UX concern (no substantial backend change), assign it directly to `owner:lucos-ux` as the implementer (see Implementation Assignment above). UX consultation via this follow-up is only for genuinely mixed work where the backend and frontend are both substantial.

**Keep triage-phase UX input narrow.** When lucos-ux is consulted during triage, they should flag only (a) items that genuinely block implementation, (b) scope questions that need a decision from lucas42, and (c) fundamental design concerns. Detailed implementation guidance (specific HTML/CSS/copy/a11y recommendations) is implementation-phase output, not triage-phase. If a triage review from lucos-ux is going deep into implementation detail, that's a signal to either (i) accept the review but recognise it's not the kind of input a triage pass needs, or (ii) reassign the ticket to lucos-ux as implementer so the detail can be applied directly during the work.

All three follow-up checks also apply mid-lifecycle: if a specialist concern is raised in an agent's comment during consultation, consult the relevant specialist next before approving.

#### Verify security-related claims from other agents

When any agent makes a statement about a security-related process — e.g. how Dependabot behaves, how secrets are rotated, how auth tokens expire — do not take it at face value. Send the claim to `lucos-security` for verification before acting on it or relaying it to the user.

#### Security input on security-related decisions

When you need a steer on a matter that has security implications — e.g. whether to close vs merge dependency update PRs, how to handle exposed credentials — consult `lucos-security` and include their input in your summary to the user.

---

## Implementation Assignment

When marking an issue `agent-approved`, also assign an `owner:*` label to indicate who will implement it. The default is `owner:lucos-developer`. Exceptions:

- **Architecture Decision Records (ADRs) and architectural documentation**: `owner:lucos-architect`.
- **Purely infrastructure changes** (Docker config, deployment, server setup with no application code): `owner:lucos-system-administrator`.
- **Purely monitoring/logging/pipeline work** (deployment pipelines, alerting, observability with no application code): `owner:lucos-site-reliability`.
- **Investigation and diagnosis of production failures** (connection errors, timeouts, resource exhaustion, unexplained crashes — issues that say "investigation needed" or require checking logs, infrastructure state, or resource usage): `owner:lucos-site-reliability`. Do not default these to the developer just because a code fix might eventually be needed — the SRE is better equipped to diagnose the root cause first.
- **Incident management** (incident response, incident reporting, post-mortems, incident tracking): `owner:lucos-site-reliability`.
- **Purely security work** (authentication setup, vulnerability remediation with no application code): `owner:lucos-security`.
- **Frontend and UX work**: `owner:lucos-ux`. lucos-ux is both advisor and implementer for frontend-heavy tickets.

  **The rule: owner = where the dominant lines of code will live, not where the user impact lands.** A ticket is `owner:lucos-ux` only if the bulk of the work is in user-facing markup, styles, or copy. A ticket can be "about UX" at the concept level while its implementation is dominantly engineering — in that case the owner is `lucos-developer` (or another specialist) with UX consultation, NOT `lucos-ux`.

  **Patterns that ARE `owner:lucos-ux`:**
  - **Layout and styling bug fixes.** "X overlaps Y", "footer floats wrong", wrong spacing, wrong colour, broken layout, screenshots of visual bugs. CSS work regardless of what backend language the project uses.
  - **Server-rendered template work** in PHP / EJS / Jinja / Go templates / ERB / etc. where the controllers are thin framework boilerplate fetching data and handing it to a view. Test: "is the design question about what the user sees, or about how data flows?"
  - **"Show a clearer error message when X fails"** tickets where the dominant concern is message wording and visual presentation, and the backend detection is a trivial property check or branch (~5–10 lines). Non-trivial detection (new model fields, async logic, retry policies) makes it a backend ticket instead.
  - **HTML / CSS / frontend JavaScript** where the JS is presentation-level (DOM manipulation, form validation, simple interaction state) rather than business logic.
  - **Accessibility implementation**, UI form layouts and field interactions, copywriting on user-facing surfaces, UX audits, information architecture scoped to a UI.

  **Patterns that are NOT `owner:lucos-ux` even though they may have user-visible effects** — these go to `lucos-developer` (or the relevant specialist), with UX consultation on any user-facing surface area:
  - **Admin framework customisations** — Django admin (`admin.py`), Flask-Admin, ActiveAdmin, Wagtail admin, and similar. These are "user-facing pages" but the implementation is entirely in the framework's configuration language (Python class attributes, decorators, model registrations). The framework generates the markup. UX should be consulted on field labels and destructive-action confirmation copy, but the ticket goes to whoever owns the backend language.
  - **Web Platform infrastructure** — service workers, IndexedDB / Cache API, fetch interception, offline plumbing, WebSocket plumbing, push notifications. Engineering plumbing that enables user-facing behaviour but isn't implemented in UI code. UX should be consulted on user-visible surfaces (offline indicators, fallback messaging, permission-prompt copy).
  - **Frontend JavaScript that is dominantly business logic**, data sync, or state management rather than presentation.
  - **Backend endpoints that serve data to a UI.**

  See the full Scope of Work in `agents/lucos-ux.md`. When unsure, default to `owner:lucos-developer` and add a UX consultation for the user-facing surface area.
- **Workflow and process documentation** (issue conventions, label conventions, triage process, agent workflow docs): `owner:lucos-issue-manager`.
- **Mixed work** (infrastructure + backend coding, security + backend coding, substantial frontend + substantial backend, etc.): `owner:lucos-developer`. Ensure the relevant specialist has reviewed the issue first.
- **If unclear**: `owner:lucos-developer`.

---

## Priority Labels

Assign a `priority:*` label to **every issue during triage** — not just `agent-approved` issues. This includes `needs-refining` issues routed to `owner:lucas42` or any agent. Early prioritisation helps lucas42 and agents understand which refinement work is most urgent.

Consult the **strategic priorities file** at `~/sandboxes/lucos/docs/priorities.md` to determine the correct priority level.

| Label | When to apply |
|---|---|
| `priority:high` | High impact on users or other work; should be picked up soon. |
| `priority:medium` | Standard priority; pick up in normal queue order. |
| `priority:low` | Nice to have; only pick up when the queue is otherwise clear. |

Issues without a priority label have **not yet been prioritised** — this is distinct from `priority:medium`.

When picking up work, agents process issues in priority order: `priority:high` first, then `priority:medium`, then `priority:low`. Within the same priority level, oldest issues first.

**Re-assessing priority after lucas42 input:** When lucas42 gives input on an issue, re-assess the priority. Update the `priority:*` label accordingly.

**Priority override rules:**
- **lucas42's priority calls override strategic priorities.** lucas42 is the repo owner and has final say.
- **Priority calls from others** (including other agents) should be considered within the context of the larger strategic priorities defined in `priorities.md`.

---

## Central Label Controller

**The coordinator is the sole agent responsible for managing labels across all lucos issues.** No other agent adds, removes, or changes labels. This is deliberate: a single point of label control means there is always a consistent, auditable view of each issue's status.

For issues that were labelled with `owner:` and `needs-refining` in a previous session, detect completed agent work:
- If an agent's comment is the most recent activity, treat it as their completed input
- If the agent's work is clearly complete and uncontroversial, transition directly to `agent-approved`
- If it needs sign-off from lucas42, transition to `status:awaiting-decision` + `owner:lucas42`

**Reactions as approval:** If lucas42 adds a +1 reaction to a comment, treat that as approval of the recommendations in that comment. This applies to any comment, but is most relevant when an agent has posted a design proposal or set of recommendations:

- If the +1'd comment contains a design proposal or implementation plan, treat the design as approved and transition the issue to `agent-approved` (assuming no other blocking questions remain).
- If the +1'd comment lays out multiple options with a recommendation, treat the +1 as agreement with the recommended option.
