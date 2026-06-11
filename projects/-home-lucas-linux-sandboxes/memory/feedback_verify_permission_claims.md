---
name: feedback-verify-permission-claims
description: "Never assert that a bot lacks a GitHub permission without checking — probe the API or the App's permission listing first."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a23edcc7-37e5-4107-a650-cc9771a7273d
---

When telling a teammate "you can't do X because your bot lacks permission Y", verify it first. Don't propagate "{action} must be done by lucas42 because the {bot} doesn't have {permission}" as a fact — that's a guess until you've checked.

**Why:** On 2026-05-20, asserted in a SendMessage to `lucos-developer` that "Dismissals must be by lucas42 since lucos-developer[bot] doesn't have the permission" — without checking the GitHub App permissions of `lucos-developer[bot]` or `lucos-security[bot]`. The claim was then echoed in security's action summary and back to lucas42 as if it were established fact. lucas42 correctly asked "whose assertion was it that dismissal should be my job?" — the answer was mine, unverified. This is the same family as [[feedback_verify_before_propagating]] but for permission claims rather than identifier values.

**How to apply:**

- When you're about to write "{bot} doesn't have permission to X" / "only lucas42 can X" / "this needs sysadmin permissions" in any SendMessage, GitHub comment, or user-facing reply: STOP. Verify first.
- **Aggregate/universal claims require probing EVERY app, not a sample.** "No app in the team holds permission X" is a stronger claim than "{bot} lacks X" — it's only verified once you've probed each app individually (or read each app's permission listing). On 2026-06-10 I probed only lucos-issue-manager (403) and lucos-site-reliability (actions:read) for `actions:write`, then asserted to lucas42 that *no* team app had it — and proposed raising an issue to "fix the gap." The sysadmin app held `actions:write` all along (a one-line `rerun` probe confirmed it), so the gap — and the proposed issue — didn't exist. If you can't probe all of them, narrow the claim to the ones you tested ("issue-manager and SRE lack it; haven't checked the others") rather than generalising to "none."
- Verification options: (a) check the App's permission listing in `~/sandboxes/lucos_agent/` or in GitHub Settings; (b) probe via the API as the bot (try the action and see if it returns 200 or 403); (c) ask the bot itself, since it can probe its own permissions cheaply.
- If verification isn't practical right now, frame it as a question rather than an assertion: "I think only lucas42 can do this — can you verify?" rather than "lucas42 is the only one with the permission."
- Specific actions worth probing rather than guessing about: CodeQL alert dismissal, secret-scanning alert dismissal, branch protection changes, repo settings changes, GitHub App installation modifications, project board admin actions.

The cost of getting this wrong is that lucas42 has to do work a bot could have done, OR the team builds a process around a non-existent constraint, OR an agent gets blamed for "not having permission" when they actually do. All of those happened in some form during the 2026-05-20 PR #460 loop.

Related: [[feedback_verify_before_propagating]] (identifier values), [[feedback_no_unverified_endorsement]] (don't endorse without verification), [[feedback_refetch_before_accusing]] (re-fetch before accusing an agent of inaction).
