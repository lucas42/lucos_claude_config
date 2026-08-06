---
name: positive-control-verification
description: When a design assessment claims "X must ship with Y or state Z breaks," deliberately force state Z on a running instance and confirm X alone doesn't fix it, then confirm X+Y does — don't just verify the happy path
metadata:
  type: feedback
---

Confirmed good practice (team-lead, lucos_worlds#61/#75): when an architect's or your own assessment claims a specific failure mode requires two things to ship together — e.g. "removing the toggle without clearing the persisted preference would strand anyone already in dark mode" — verify that claim with a positive control on a running instance, not just by reading the reasoning and trusting it, and not just by testing the fix's happy path.

**What this looked like in practice:** before shipping the dark-mode-toggle removal, I forced the "already in dark mode" state directly (set the persisted `dark-mode-enabled` setting to `true` via `SettingService`), confirmed the toggle-removal half *alone* did NOT undo it (heading still measured the broken ~1.7:1 contrast), then confirmed the container-restart clear-script half *did* fix it. That's the actual failure mode the two-halves-must-ship-together claim was about — testing only "toggle is gone" and "heading looks fine after a fresh container start" would have missed whether the stranding scenario was really handled.

**Why this matters more than usual verification:** a claim about a *consequence of an omission* ("if we don't do Y, X breaks") is easy to state confidently and easy to leave unverified, because the natural test path (fresh install, both halves already present) never actually exercises the omission. The same "trust and move on" mistake caused the specificity-collision bug this same PR caught the second time round — a plain `:not(:has(*)) { display: none }` silently lost to BookStack's own `!important` rule, only found by inspecting `getComputedStyle` on a running instance rather than assuming the selector won.

**How to apply:** whenever a plan says "A and B must ship together, or [bad thing] happens," before calling it done: (1) deliberately create the state the plan warns about, (2) apply only the partial fix, confirm the bad state persists, (3) apply the full fix, confirm it's resolved. This is cheap on a local dev instance and catches exactly the class of bug that a "did it work" smoke test cannot.
