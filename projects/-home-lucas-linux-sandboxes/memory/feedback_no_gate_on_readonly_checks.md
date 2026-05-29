---
name: feedback_no_gate_on_readonly_checks
description: "Don't ask permission to run safe read-only verification checks — just run them and report"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9dec23f5-2604-4ec2-a4fa-ad772fae61b5
---

When a read-only verification would help the current goal (e.g. confirming a production deploy/migration state, checking an API's `/_info`, reading a config), **just run it and report the result** — do not offer it as a question or wait for sign-off. lucas42 pushed back on being asked "do you want me to verify the api#237 production migration gate? (read-only)" — the answer is obviously yes and the asking is pure friction.

**Why:** The confirm-first rule is for actions that are *hard to reverse* or *outward-facing* (writes, deploys, sending content externally, closing/merging PRs). A read-only query is neither. Conflating "touches production" with "needs sign-off" is the specific error — read-only access to production is safe and needs no gate. Dispatching a teammate (e.g. `lucos-site-reliability`) to perform a read-only check is still a read-only action overall.

**How to apply:** Before offering a verification/check as an AskUserQuestion or a "want me to…?" prose offer, ask: *does this action change any state or leave the system?* If no, skip the offer — perform it and report. Reserve confirmation for state-changing or outward-facing steps. Companion to [[feedback_ask_about_the_plan_first]] and the take-the-first-action rule in `references/teammate-communication.md`.
