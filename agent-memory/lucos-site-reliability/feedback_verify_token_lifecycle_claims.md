---
name: feedback-verify-token-lifecycle-claims
description: Token/invite lifecycle behaviour (revocation, single-active enforcement, TTL, what voids what) is a claim about actual implementation — verify against the store/code before asserting, or hedge explicitly
metadata:
  type: feedback
---

Statements about token / invite / credential **lifecycle** — does generating a new one revoke the old, is there single-active enforcement, what's the TTL, what consumes/voids what, is there a revocation path — are claims about the system's *actual implementation*, not safe defaults to assume.

**Why:** during the 2026-06-12 aithne CA-bundle incident I asserted "a fresh `--bootstrap-invite` supersedes" the unconsumed test invite. That was an unverified assumption — it propagated to lucas42 via team-lead before anyone checked the store. lucos-security read `store/enrolment_invite.go` and the truth was the opposite: only `CreateInvite` (plain INSERT) + `GetInviteByRawToken`, no revocation, no single-active enforcement, `InviteTTL = 24h` — so a fresh invite coexists with the old, both valid independently. team-lead reinforced (2026-06-12): "invite/token lifecycle behaviour … state it only after checking the store/code, or hedge it explicitly."

**How to apply:** before stating any lifecycle behaviour (especially in a report, an issue, or a message that will reach lucas42), grep/read the store or handler that implements it. If you can't verify before you must speak, hedge unmistakably ("I haven't checked the store, but I'd expect…"). This is the global [[Hedge Unverified Claims]] rule applied to a class that *looks* like common sense but is implementation-defined. Same trap as asserting state from memory — re-fetch or hedge.
