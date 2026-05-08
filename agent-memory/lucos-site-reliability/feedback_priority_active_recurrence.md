---
name: Active recurrence justifies higher priority than default-P3
description: When a flap or alert is currently recurring in production, the root-cause fix warrants higher-than-default priority — don't default to P3 just because impact is "user-invisible"
type: feedback
---

When filing an issue for a recurring flap or alert pattern that is **still firing in production today**, default to at least `priority:medium` rather than P3 — even when user-visible impact is bounded.

**Why:** team-lead bumped `lucos_media_metadata_api#216` from my filed P3 to `priority:high` on 2026-05-08 with the reason "active alert recurrence + production reliability impact." I had calibrated it as P3 on the basis that monitoring flaps don't reach end-users, but the relevant fact was that the issue *was firing today* and causing daily ops-check toil — that's enough evidence of impact to bump priority above the "user-invisible reliability cleanup" default.

The two-axis rule:
- **Currently recurring in production** → at least `medium` (high if the failure mode could escalate or is actively masking other signal)
- **Bounded historical incident, fix is hardening** → P3 is appropriate

**How to apply:** when filing a flap-investigation issue from ops checks, ask: "is this still happening on the dashboard / in Loganne right now?" If yes, propose `priority:medium` minimum in the issue body. Don't conflate "user-invisible" with "low priority" — production reliability is its own axis, and a daily flap is a daily ops-check expense.

(Counterexample: `lucas42/lucos_docker_mirror#64`, also filed today, was kept at `priority:medium` not high — the `non-map metric` warning is recurring but only causes log noise + a missing canary metric, no flap or alert. So "active recurrence" alone isn't enough; the priority calibration also needs the failure to be actually masking signal or causing operator toil to justify high.)
