---
name: Parallel-drafting rule applies to in-hand verification windows; ask before applying it to externally-gated ones
description: The "don't gate drafting/shipping on long-running verification" rule was designed for verification windows you control (cron rerun, soak window, deploy propagation). When verification is gated on a separate PR's lifecycle (multi-day, out of your hands), confirm with team-lead before shipping the PR with TBDs.
type: feedback
---

The standing incident-reporting rule says: ship the report PR even with verification-pending TBDs, because durable state-in-git matters more than tidy first commits, and verification windows can outlast a work session.

That rule assumes verification is **in your hands** with a finite window measured in minutes-to-hours: an ad-hoc cron rerun, a soak window after a fix, a deploy propagation cycle. In those cases the TBDs get filled in within the same session or the next one, and shipping early just means cheap fill-in commits or a follow-up PR.

**When verification is gated on a separate PR's lifecycle** — e.g. lucas42 chose to wait for `lucos_backups#266`'s `update-authorized-keys.sh` rather than running an ad-hoc unstick on aurora, making aurora's recovery wait on dev → review → merge → run-script — the verification window becomes multi-day and out of your hands. Shipping the report PR with TBDs in that case can leave a stale half-finished doc in a merged state for days, which is worse than holding the PR.

**Why:** team-lead intervened on 2026-05-09 and overrode my "ship per the standing rule" reflex on PR lucas42/lucos#135 (the SSH-key-rotation incident report) for exactly this reason. The instruction was: convert to draft, hold the branch, fill in and mark ready-for-review only after aurora actually clears. I had to convert the PR to draft and tell `lucos-code-reviewer` to stand down on the review I'd already requested.

**How to apply:** When the next steps to verification depend on someone else's PR shipping (or any other multi-day-out-of-your-hands lifecycle), ask team-lead before applying the standing parallel-drafting rule. Acceptable answers are "draft and hold" or "ship per the standing rule" — both are fine, but the call is team-lead's, not the standing rule's. The rule's "verification windows can outlast a work session" framing covers minutes-to-hours, not days-gated-on-other-PRs.

This sub-rule is also worth flagging back to the coordinator if it keeps coming up — likely candidate for an explicit clarification in `references/incident-reporting.md` between "in-hand verification" and "externally-gated verification." Don't propose that update on a single occurrence (this one) — wait for a second case to confirm the pattern.
