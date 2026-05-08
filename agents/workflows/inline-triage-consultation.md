# Workflow: inline triage consultation

This workflow is triggered when the coordinator (team-lead) consults a teammate inline during triage — typically with a SendMessage that asks for the teammate's opinion on a specific issue without dispatching them to implement it. Substitute your own persona name where this file uses `<persona>`.

Read this file in full at the start of the workflow.

## When this applies

The coordinator runs inline consultation as part of the `/triage` skill. Issues that need specialist input get a comment posted by the relevant specialist before triage moves on. The specialist's comment becomes the durable record; the SendMessage reply to team-lead is just a routing signal.

This workflow is distinct from "implement issue {url}" — you are NOT being asked to ship a PR. You are being asked to weigh in on the design or routing.

## Step 1 — Read the issue first

Use the GitHub API. Don't rely on memory from previous interactions with the issue.

```bash
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues/{number}
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues/{number}/comments
```

Read the body **and all comments**. Note any reactions on comments — a `+1` from `lucas42` on a proposal is an approval.

## Step 2 — Review the proposal's assumptions before reasoning within them

When the issue (or the team-lead's framing) proposes a particular tool, channel, library, schema, or approach, do **not** accept it as the frame. Especially for cross-cutting choices — observability, communication, schema, infrastructure, anything that affects more than one service — weigh the proposed approach against alternatives explicitly. Ask:

- Why this and not the obvious alternatives?
- Was this an explicit choice or a default that drifted into being?
- What's the cost of being wrong, and is the rigour proportionate to it?

If the proposed approach is sound on inspection, say so in your comment and explain why. If it isn't, name the alternatives and weigh them honestly in the comment itself. lucas42 prefers a comparison that justifies a choice over a thorough plan executed inside an unexamined default.

## Step 3 — Post your full assessment as a comment on the issue

This is the load-bearing artefact — it's the durable record that other people and future agents can read. Post it BEFORE replying to team-lead.

Use `gh-as-agent` with your persona's app. See [`references/agent-github-identity.md`](../../references/agent-github-identity.md) for the heredoc and file-backed body patterns.

The comment should be a substantive write-up — the same depth you would put in an architectural assessment or a code review. Include:

- Your read of the problem.
- The options you considered (especially if the framing proposed one as the default).
- The trade-offs.
- Your recommendation, with the reasoning behind it.
- Any open questions that need a decision before implementation can proceed.

## Step 4 — Reply to team-lead with a short summary

After the comment is posted, send a short SendMessage back to team-lead summarising:

- The decision or recommendation.
- The suggested next step (owner persona, routing via `/dispatch` vs `/estate-rollout`, priority signal).
- A pointer to the comment URL on the issue.

The team-lead doesn't need the full assessment in the message — they have the comment URL.

## Step 5 — Don't ask for permission to post the comment

The comment is part of the consultation — it's your job, not a permissioned action. Asking "just say the word and I'll post it" puts the ball back in team-lead's court for no reason and forces them to route the comment back through you. Just post it.

The only exception is if the comment would be premature — e.g. you genuinely need a clarifying question answered by lucas42 before you can form an opinion. In that case, post the clarifying question as the comment and say so to team-lead.

## What you don't do

- **Don't touch labels.** Triage is the coordinator's job. See [`references/label-workflow.md`](../../references/label-workflow.md).
- **Don't start implementing.** Inline consultation is design input, not a dispatch. Do not branch, write code, or open a PR. If the issue needs implementing, the coordinator will dispatch you with `"implement issue {url}"` separately.
- **Don't summarise the issue back to team-lead** — they read it. Tell them what you've decided and where the comment is.

## Persona-specific extensions

Personas may layer on top of this workflow with their own decision criteria:

- **lucos-architect** — frame-review applies particularly hard to cross-cutting infrastructure choices.
- **lucos-security** — explicitly enumerate the threat model and attack surface in the comment.
- **lucos-site-reliability** — explicitly enumerate failure modes, blast radius, and observability gaps.
- **lucos-developer** — call out concrete implementation risks (test environment, rebuilds, dependency churn).

Persona-specific guidance must not contradict the steps above.
