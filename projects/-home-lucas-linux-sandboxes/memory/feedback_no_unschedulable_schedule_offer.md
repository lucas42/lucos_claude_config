---
name: feedback-no-unschedulable-schedule-offer
description: "Don't offer /schedule for tasks a remote cloud routine can't actually perform (production SSH, gh-as-agent, local files)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f9e2917c-8177-41f8-a17d-a299feb63d76
---

Never offer to `/schedule` something that can't actually be scheduled. `/schedule` routines run as **remote agents in Anthropic's cloud** — no SSH to avalon/xwing/salvare, no `gh-as-agent`, no local files/services. So any task needing production access (reading a host's `docker logs`, deploys, enforce flips, posting via `gh-as-agent`, reading local repos) **cannot run as a remote routine**.

**Why:** On 2026-06-01 I offered to `/schedule` the lucos_firewall dry-run log review (lucos#182, due 2026-06-08), lucas42 said yes, and only then did I discover the review needs production SSH that remote routines lack — so I had to walk the offer back. lucas42's instruction: "in future don't offer to `/schedule` something that you can't actually schedule." The harness "/schedule offer" guidance fires on any future-dated obligation, but in the **lucos estate most ops 'future obligations' (log reviews, deploys, enforce flips, audit reruns) need production access** — so they are NOT remotely schedulable.

**How to apply:**
1. Before *offering* (not just before creating) a `/schedule`, run the feasibility gate: does the task need production SSH, `gh-as-agent`, or local files? If yes → it can't be a remote routine; **don't offer it.**
2. For lucos ops follow-ups that need production access, the right pattern is **session-triggered local execution**: post a dated reminder on the relevant ticket + a project memory, and have the local team (which has production SSH) run it when a session is active on/after the date. See [[firewall-rollout-state]] for the worked example (2026-06-08 review).
3. A remote routine is only viable for work a cloud agent can do alone (pure web research, reasoning over pasted content, or against a remote env explicitly wired with the needed creds — confirm that wiring exists first).
