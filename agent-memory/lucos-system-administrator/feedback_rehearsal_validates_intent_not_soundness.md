---
name: feedback-rehearsal-validates-intent-not-soundness
description: A disposable-repo rehearsal proves the code does what you built it to do, not that what you built was the right thing — ask whether the observation would look different if the design itself were wrong
metadata:
  type: feedback
---

On lucos_claude_config#129/#130/#131 (2026-08-18): built a "gate `check_persistent_dirt` on sync success" fix, rehearsed it in a disposable repo, and recorded the pass criterion as *"the state file is never created/touched while sync is failing, only the existing sync-failure WARNING fires."* That correctly confirmed the code did what I intended. `lucos-architect` pointed out the behaviour it confirmed **was the defect**, written down as the pass criterion — suppressing the persistence check during exactly the condition (repeated sync failure, index staleness, `origin/main` still advancing) it existed to catch.

**Why:** a rehearsal validates implementation-matches-intent. It cannot validate that the intent was sound, because a faithful rehearsal reproduces whatever you asked it to build — right design or wrong. The habit of testing before pushing (confirmed useful elsewhere this session — see [[pr-merged-stale-commit-despite-later-push]] for a different failure the same session caught) is necessary but not sufficient on its own.

**How to apply:** before trusting a rehearsal's green result, ask explicitly: *"would this observation look different if the design itself were wrong?"* If the answer is no — if a flawed design and a sound one would both produce the same passing test — the rehearsal isn't evidence for the design, only for the implementation of it. Applies most sharply to defensive/suppression logic (gates, guards, filters): confirming the gate gates is not confirming the gate should exist.
