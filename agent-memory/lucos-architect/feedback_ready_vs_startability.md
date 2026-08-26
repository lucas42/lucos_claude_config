---
name: feedback_ready_vs_startability
description: Inline-triage consultation must not conflate "can start coding in parallel" with Status = Ready; unresolved dependencies require Blocked regardless of how much pre-work is independent
metadata:
  type: feedback
---

When consulting inline on a triage call, do NOT use "implementation can start in parallel" or "code can be written and unit-tested against fixtures" as a Ready signal. The triage procedure (`references/triage-procedure.md`, "Cross-issue dependencies") is explicit: **unresolved dependency → Status = Blocked, even if the design is fully agreed**.

**Why:** Ready is a triage state about end-to-end completability and verifiability, not about whether coding can start. "Parallel-startable" is a developer-ergonomics framing — relevant to scheduling, irrelevant to triage status. A ticket whose work cannot be considered complete until another ticket lands is Blocked; that the implementer can write some of the code in parallel does not change this. Treating parallel-startability as a Ready signal lets blocked work into the dispatch queue, where the implementer hits the dependency wall during verification and either ships an incomplete change or has to park the PR. lucas42 caught this on `lucos_arachne#539` (consultation 2026-05-17, corrected 2026-05-18) — original framing said #712 was "only required for end-to-end testing" so Ready was fine; that's exactly the framing this rule rejects.

**How to apply:** When my architectural assessment of an issue is positive on design but I notice an external dependency in the body or comments, the consultation answer to team-lead is: "design is sound; depends on `<ticket>` — recommend Blocked until that closes." Do NOT say "implementation can start in parallel" as if it justifies Ready — the parallel-startability point is at best an implementation-planning footnote, never a triage signal. If I genuinely want to flag that some pre-work is independent (e.g. for scheduling reasons), I'll mention it as such, not embed it in the Ready/Blocked decision.

**Same shape, different question — when to FILE deferred work.** Deciding whether a deferred follow-up should be filed now or held, the test is **"does it survive the decision going the other way?"** — not "is it part of my recommendation?". The second feels decisive and answers a different question. (2026-08-26, lucas42/lucos_repos#488: I argued the constraint check was "part of the recommendation rather than downstream of it", so should be filed immediately. True, and irrelevant — if Decision B landed on `--deploy` instead, what ships alongside is a *different* check and this one may not be wanted at all. So it was contingent after all. The coordinator caught it.)

Note the pairing with the *opposite* error in the same ticket: revising the recommendation to include the deferred check was right (otherwise `sync` gets compared on its best case while the alternative carries its full cost), but that revision belongs in the **body**, not a ticket — a reader weighs what is in front of them. **Fix the framing where the decision is read; file the ticket when the decision is taken.**

Related: [[reference_architecture_review]] / [[feedback_implementation_surface_code_trace]] (similar pattern of mistaking design-readiness for implementation-readiness), [[option-list-is-an-absence-claim]].
