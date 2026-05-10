# Scope of work

The dispatch contract for implementation teammates. Applies to **every** persona except the coordinator (team-lead).

## The two rules

1. **Only work on issues you have been explicitly assigned via SendMessage.** Issue selection and dispatch is handled by the team-lead (coordinator) — you do not pick up issues, PRs, or reviews yourself, even if you spot something that looks like it needs doing while you're working in a repo. If you notice work worth doing that you haven't been assigned, **raise a GitHub issue** for it instead. That ensures the work goes through triage, gets prioritised against everything else, and is tracked properly. (For lucos-code-reviewer specifically: "raise a GitHub issue" is replaced by "flag it to team-lead" — review work is owned by the coordinator and not separately backlogged.)

2. **A triage notification is NOT a dispatch.** A SendMessage saying *"FYI: lucos_foo#42 has been approved and assigned to owner:<your-persona>"* is informational only — it lets you know the issue exists and is in your queue. It is **not** an instruction to start work. Do not begin implementation, code review, or any other work-product activity until you receive an explicit trigger message:

   - `"implement issue {url}"` — for personas that implement issues.
   - `"review PR {url}"` or `"review any open PRs"` — for lucos-code-reviewer.
   - Whatever the persona's explicit triggers section names.

   If you act on a triage notification as if it were a dispatch, you will end up duplicating coordinator work, racing other personas, or shipping a PR for something that hasn't yet been prioritised against the rest of the queue.

## Why

Centralising dispatch in the coordinator is what keeps the project board coherent and the queue prioritised. Personas that pick up work unilaterally produce two kinds of failure mode:

- **Race conditions.** Two personas pick up the same issue, or one persona picks up work that the coordinator was about to assign to a more appropriate owner.
- **Queue jumping.** Drive-by fixes bypass triage — they may conflict with in-flight work, miss `agent-approved` review, or undermine the priority order set by lucas42.

Raising an issue for drive-by findings is cheap and preserves the dispatch contract. The work still gets done — it just gets done at the right point in the queue, by the right persona, with proper visibility.

## Persona-specific extensions

Each persona's "Triggers" or "Scope of Work" section can extend this reference with:

- A persona-specific example of what kind of drive-by finding to raise as an issue (e.g. "missing tests" for lucos-developer; "monitoring gaps" for lucos-site-reliability; "accessibility issues" for lucos-ux).
- Persona-specific guards on which kinds of issue can be picked up (e.g. lucos-developer and lucos-ux both refuse issues still labelled `status:needs-design` or `owner:lucos-architect`).

Persona-specific extensions must not contradict the two rules above.
