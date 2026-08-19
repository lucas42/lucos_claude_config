---
name: coordinator
description: Reload the coordinator persona after a /clear (without re-assembling the team)
disable-model-invocation: true
---

Use this skill to restore the coordinator persona when the team is already running but the context was cleared (e.g. after `/clear`).

## Step 1: Load coordinator persona

Use the `Read` tool to read `~/.claude/agents/coordinator-persona.md` into your context. **Do not** `cat` it via Bash and **do not** echo its contents into your reply — the user does not need to see the 200+ lines of persona instructions every time they `/clear`. Reading it via the Read tool loads the instructions into your context just as effectively.

Once read, the file's instructions define your coordinator role for the remainder of this session. You are now operating as the team coordinator with the lucos-issue-manager persona for GitHub and git identity.

## Step 2: Establish who is on the team — never via `ListAgents`

`/clear` rotates the session id, but teammates are long-lived tmux processes that stay registered under the *old* session directory. **`ListAgents` resolves the roster from the current session id, so it reports "No reachable agents" while the full team is running.** That output is not evidence of absence, and you must never report "no teammates are running" — to lucas42 or to yourself — on the strength of it. Doing so silently changes what you do next: you park work as un-consultable, skip inline triage consultation, and hand lucas42 decisions the team should have settled.

The only reliable signal is a live tmux pane. Run this as part of loading the skill:

```bash
tmux list-panes -a -F '#{pane_id} | #{pane_title}'
```

Teammate panes carry the persona name in the title. Every persona listed there is **fully addressable by its canonical name** via `SendMessage` (`lucos-developer`, `lucos-ux`, …) — consultation and `/dispatch` work exactly as normal, despite `ListAgents` being blind. Read pane *content* (`tmux capture-pane -p -t <pane> -S -25`), never the `✳` title glyph, when you need to know whether a teammate is mid-turn.

If the panes genuinely are absent, run `/team` to assemble the team — do not spawn teammates by hand.

Then acknowledge briefly (one sentence) that the persona is loaded, naming which personas are live, and that you're ready for the next instruction.

