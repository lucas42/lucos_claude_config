---
name: triage
description: The coordinator triages all open issues with inline agent consultation
disable-model-invocation: false
---

Perform triage directly and summarise the results. Do not ask for clarification — immediately begin.

## Step 1: Memory Review of Closures of Issues You Authored

Check whether any issues you (lucos-issue-manager) previously raised have been closed, in case the closure reasoning reflects a decision or preference you should remember:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager \
  "search/issues?q=author:app/lucos-issue-manager+org:lucas42+is:issue+is:closed+sort:updated-desc&per_page=10"
```

For each unfamiliar closure: read the final comments. Skip issues you've already reviewed. Update memory only if there is something genuinely new — most closures are routine completions and need no action.

## Step 2: Board-wide Done-column Sweep

Closed issues should not remain on the project board. The built-in workflow moves them to the Done column on close, but they must then be deleted entirely. **This sweep is board-driven, not author-driven** — query the board for items with `Status = Done` (`optionId == "878c350f"`) across **all pages** and delete every one with `deleteProjectV2Item`. The previous (author-scoped) cleanup missed closures by other bots and let backlog accumulate to ~100 items.

Do this in a loop that re-fetches page 1 each round, since deletes shift items forward. A single shell loop running until page 1 contains no Done items is the simplest correct pattern. Keep going until the sweep reports zero Done items found.

## Step 3: Discover and Triage Issues

```bash
~/sandboxes/lucos_agent/get-issues-for-triage
```

This returns a JSON array of all issues that currently need your attention. An issue is included if **any** of the following is true:

- **Status = Needs Triage** on the project board — newly added, needs initial triage.
- **Status = Ideation or Awaiting Decision** and the most recent comment is NOT from `lucos-issue-manager[bot]` — an owner agent has probably completed work and the issue needs a status transition (or someone has replied and it needs another look).
- **Owner = lucos-issue-manager** on the project board — explicitly routed back to you for action.
- **Status = Ready with a fresh `lucas42` comment** — the issue was previously approved, but `lucas42` has commented more recently than the most recent `lucos-issue-manager[bot]` comment. The comment may be a substantive scope change (re-triage needed), a clarification to bake into the body, or an FYI. Re-evaluate per [`triage-procedure.md`](../../references/triage-procedure.md)'s **"If lucas42 has commented on an already-approved issue"** section.
- **Not on the project board at all** — fallback for issues that predate the board or were missed by the board scan.

Pull requests and archived repositories are excluded.

Work through each issue using the full triage procedure in `~/.claude/references/triage-procedure.md`. Also read `~/.claude/references/triage-reference-data.md` for project board IDs, field mappings, and API patterns. When consulting agents during triage, wait for each response before re-assessing the issue. Triage is complete when all issues are processed and all consultations are resolved.

If the script returns an empty array, report that there is nothing needing triage right now.

**Never revert a project board field change without reading the comments first.** If an issue you previously set to Status = Ready now appears at a different status, someone (likely lucas42) changed it deliberately. Read the comments to understand why before taking any action.

### Reactions are answers — check them every pass

lucas42 frequently approves a proposal by reacting `+1` to the comment that contains it, rather than typing a confirmation. Comments alone are not enough — **reactions must be checked explicitly on every pass**, both for issues you are re-processing in Step 3 and for any Owner = lucas42 issue you are about to list in the Step 6 summary.

For every issue with Status = Awaiting Decision AND Owner = lucas42 on the project board:

1. Fetch reactions on each comment that asked a question of lucas42, proposed an option, or laid out a design (typically the architect's, SRE's, or your own comments — *not* lucas42's own comments).
   ```bash
   ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager \
     "repos/lucas42/{repo}/issues/{number}/comments" --jq '.[] | {id, login: .user.login, created: .created_at, plus_one: .reactions["+1"], total: .reactions.total_count}'
   ```
2. If any such comment has a non-zero `+1` count, fetch the reaction's authors:
   ```bash
   ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager \
     "repos/lucas42/{repo}/issues/comments/{comment_id}/reactions" --jq '.[] | "\(.content) by \(.user.login)"'
   ```
3. **A `+1` from `lucas42` on a comment that posed a question or proposed a design is an approval** — treat it as if lucas42 had typed "yes, agreed" beneath that comment. Re-process the issue accordingly: bake the proposed shape into the body, set Status = Ready + Owner = appropriate implementation persona on the project board, and post a comment acknowledging the reaction was the answer.

   **Superseded-proposal caveat.** A `+1` from `lucas42` only counts as approval of the *current open question*. If a later comment from the same author has refined or replaced the proposal the `+1` was on, the `+1` has lapsed. Concretely: compare the reaction timestamp against the timestamp of the most recent agent comment in the thread. If the `+1` predates a later proposal that materially changed the recommendation, treat the historical `+1` as not-current and look for a fresh reaction on the new comment instead. The discovery script will still surface the issue (criterion 2b — any historical reaction triggers the surface), but the procedure here should not transition the board status based on a `+1` that's been overtaken by a different recommendation. Leave the issue with Status = Awaiting Decision waiting for a fresh `+1` on the new proposal. (Lesson from 2026-05-12 on `lucos_eolas#19`: the March +1 was on a "eolas wins" URI strategy that the architect later replaced with "first-seen wins" — treating the historical +1 as approval of the new strategy would have been wrong.)
4. **Do not list the issue in the Step 6 summary if a `+1` from lucas42 has resolved it** — the round-trip ("you already approved this, why am I asking again?") wastes lucas42's time and is the exact pattern this rule exists to prevent.

The rule exists because reactions don't appear in the comment text feed — it is structurally easy to miss them by reading comments only. Skipping the reaction check is what produces the "Open question for you, @lucas42" comment posted *after* lucas42 has already reacted +1 to the design two minutes earlier. Don't do that.

## Step 4: Board Verification — "Needs Triage" Must Be Empty

After processing all issues in Step 3, verify that no items remain in the "Needs Triage" board column. Query the project board for items with status `79f7273e` (Needs Triage). If any are found:

- **Not yet triaged**: triage now using Step 3.
- **Needs agent design work**: a previous pass parked this instead of consulting the agent inline. Do the consultation now, then move to "Ideation" (`5f521008`) or "Awaiting Decision" (`cf5e250d`) as appropriate.
- **Waiting for lucas42 decision**: board status wasn't updated — move to "Awaiting Decision" (`cf5e250d`).
- **Clear and implementation-ready**: board status wasn't updated — move to "Ready" (`3aaf8e5e`).

**Every issue must end triage in one of these columns: Ideation, Awaiting Decision, Blocked, Ready, or Done.** "Needs Triage" is a transient processing state, not a destination. If anything is still in "Needs Triage" at the end of a triage pass, triage is not complete.

## Step 4.5: Handoff Verification — SendMessage for Every Non-Lucas42 Owner Routed This Pass

For every issue you triaged in Step 3 that ended at Status ∈ {Ideation, Awaiting Decision} with Owner ≠ lucas42, verify you SendMessage'd that agent in this triage pass with the issue URL and ask. Setting the Owner field is board-state bookkeeping — it does not notify the agent. Without the SendMessage, the work goes silent and the issue stalls indefinitely.

For each such issue, self-attest explicitly in your response: "SendMessage to <agent> for <issue URL>: sent / not sent." If "not sent", SendMessage now (with full context — issue URL, the design/verification ask, problem statement verbatim from lucas42 if applicable per triage-procedure.md). Do not consider triage complete until every non-lucas42 owner on a triaged-this-pass Ideation/Awaiting Decision item has received their SendMessage.

This step exists because the "set Owner = <agent>" board mutation feels like the action when it isn't — the actual action is the SendMessage. The board update is purely the audit record. Setting Owner without SendMessage produces a perfectly-triaged-looking ticket that no agent knows about.

## Step 5: Unblocking Check

During each triage pass, also check for issues with Status = Blocked whose dependencies may have been resolved. Before setting Status away from Blocked on an issue:

1. **Read the full issue body AND all comments** — dependencies are often added in comments by lucas42 after the initial filing. The issue body may be incomplete.
2. Identify every issue referenced as a dependency or prerequisite across both the body and comments.
3. Check that **every** dependency is closed — not just the one that triggered the check.
4. If the issue body is missing dependencies that were added in comments, **update the issue body** to include them before changing the board status. The body should be the canonical list of dependencies.
5. Only set Status away from Blocked when every dependency has been completed.
6. **Closing a dependency issue is not the same as the real-world precondition being met.** Before unblocking, verify that the underlying condition the dependency was tracking actually holds — not just that the tracking issue is closed. For example, closing "deploy secondary DNS server" does not mean the server exists. If the dependency was for physical infrastructure, a deployed service, or a third-party action (e.g. registrar update), confirm the thing actually exists before unblocking dependent work.

**Special case — false positive audit findings:** When unblocking an `audit-finding` issue whose blocker was a fix to the convention checker itself, close the issue as completed instead of just updating the board status.

## Step 6: Summary for the User

Once triage is done, compile a prioritised list of issues that need the user's attention. This means any open issue with Owner = lucas42 on the project board AND Status ∈ {Awaiting Decision, Ready} — these are issues where only the repo owner can unblock progress *right now* (e.g. product direction, priority calls, decisions between options, or a manual action only lucas42 can take).

**Exclude Status = Blocked and Status = Ideation from the summary.** Blocked items are gated on something else clearing first — surfacing them as "needs you" is noise. Ideation items are exploratory and waiting for someone to revisit when ready — not actively gating on lucas42. Both will surface in their own time (Blocked via the unblocking check; Ideation when lucas42 chooses to revisit).

To find them, query the project board for items with Owner = lucas42 (option ID `f2527ea3`) AND Status ∈ {Awaiting Decision (`cf5e250d`), Ready (`3aaf8e5e`)} that are not closed, sorted by priority:

```python
import os, subprocess, json

GH_PROJECTS = os.path.expanduser("~/sandboxes/lucos_agent/gh-projects")
PRIORITY_ORDER = {"Critical": 0, "High": 1, "Medium": 2, "Low": 3}
BOARD_QUERY = """{
  node(id: "PVT_kwHOAAaLL84BRh5d") {
    ... on ProjectV2 {
      items(first: 100%s) {
        pageInfo { hasNextPage endCursor }
        nodes {
          content {
            ... on Issue { title url state }
          }
          fieldValues(first: 10) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
            }
          }
        }
      }
    }
  }
}"""

cursor, results = None, []
while True:
    after = f', after: "{cursor}"' if cursor else ""
    r = subprocess.run(
        [GH_PROJECTS, "graphql", "-f", f"query={BOARD_QUERY % after}"],
        capture_output=True, text=True, check=True,
    )
    items = json.loads(r.stdout)["data"]["node"]["items"]
    for node in items["nodes"]:
        c = node.get("content") or {}
        if c.get("state") == "CLOSED":
            continue
        fields = {
            fv["field"]["name"]: fv["name"]
            for fv in (node.get("fieldValues") or {}).get("nodes", [])
            if fv and "field" in fv and "name" in fv
        }
        if fields.get("Owner") == "lucas42" and fields.get("Status") in ("Awaiting Decision", "Ready"):
            results.append({**c, "priority": fields.get("Priority", ""), "status": fields.get("Status", "")})
    if not items["pageInfo"]["hasNextPage"]:
        break
    cursor = items["pageInfo"]["endCursor"]

results.sort(key=lambda x: (PRIORITY_ORDER.get(x["priority"], 99), x.get("url", "")))
for issue in results:
    print(f"[{issue.get('priority', 'unprioritised')}] [{issue.get('status', '')}] {issue['url']}  {issue['title']}")
```

Present the list grouped and ordered by priority, consulting `~/sandboxes/lucos/docs/priorities.md` for the priority framework:

1. **Critical** — issues first, oldest first within the group
2. **High** — next
3. **Medium** — next
4. **Low** — last
5. **Unprioritised** — at the end (Priority field not set)

For each issue, show:
- The full clickable GitHub URL (e.g. `https://github.com/lucas42/lucos_photos/issues/5`)
- The issue title
- A one-line summary of what decision or input is needed (based on the Status field and recent comments)

If there are no Owner = lucas42 issues with Status ∈ {Awaiting Decision, Ready}, say so — that means there is nothing actively gating on the user right now (Blocked and Ideation items, if any, are intentionally excluded; see the rule above).

**Before listing any Owner = lucas42 issue in the summary, run the reaction check from Step 3 against it.** A `+1` from lucas42 on a question/design comment is an approval — re-process the issue rather than reporting it. This applies to every pass, not just to issues "actively discussed during the current session" (lucas42 may have reacted between passes).
