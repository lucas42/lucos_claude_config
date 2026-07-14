---
name: feedback_verify_before_propagating
description: three related plausibility-inference failures in one session (avalon sudoers, remote-only Pi accessibility, dropped hedge on "no incident") — the common thread is asserting past the actual evidence
metadata:
  type: feedback
---

Three corrections in one session (2026-07-14, `lucos_agent_coding_sandbox#95`/`#98`/`#99`), each caught by team-lead, each the same underlying shape with a different surface:

1. **Generalising verified command output to an unverified host** — wrote "verified on avalon, xwing, salvare" when only xwing/salvare's `sudo -n -l` output was actually captured; avalon had only been tested with a different (blanket) check. Fix: [[agent-sudo-scope]] — "verified on {hosts}" needs per-host captured output, no exceptions for siblings on the same playbook.
2. **Inferring an unprobeable environmental fact from plausibility** — "remote-only Pis have no console" sounded reasonable and was wrong (per lucas42: xwing/salvare are physically accessible, avalon is not). Fix: `references/ssh-production.md`'s environmental-facts rule — physical accessibility, hardware topology, hosting arrangement can't be verified by re-running a command; source from lucas42 or mark explicitly unknown.
3. **Dropping a teammate's explicit hedge while paraphrasing** — team-lead reported "confirmed the upgrades happened, NOT verified no incident resulted"; my paraphrase into a runbook comment read "...with no incident," asserting exactly what they'd flagged as unverified. Fix: `references/teammate-quote-verification.md` now names this failure mode directly — a hedge is part of the claim, and compressing it out during paraphrase (not misquoting, which `verify-teammate-quote` would catch) produces the same downstream harm.

**Why this kept recurring in one session:** each individual fix (verify per-host, don't infer environmental facts, preserve hedges) addresses a different *surface*, but the underlying failure is the same — writing something down with more confidence than the evidence actually supports, because the unsupported version reads more cleanly or fits the narrative being built. Team-lead's framing: good underlying work each time, the inference was the weak link every time.

**How to apply:** before any comment/issue-body/memory sentence that states a fact rather than describes an observation, ask "did I personally see this, for this specific subject (host/claim/hedge), in this session" — not "does this sound right given what I know." If the answer is no, either go verify it (per-host command, direct question to lucas42) or write the uncertainty down explicitly rather than smoothing it into an assertion. This applies with *extra* force when relaying someone else's finding — their hedge is data, not friction to edit out.
