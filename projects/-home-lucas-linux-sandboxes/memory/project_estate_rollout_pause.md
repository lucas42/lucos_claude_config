---
name: Estate rollouts paused
description: User has paused all estate rollouts; do not dispatch via /estate-rollout until explicitly lifted
type: project
originSessionId: bda02c7e-0672-4d9e-8bc3-b7999c4c89e8
---
**Estate rollouts are paused as of 2026-04-10.** Do not dispatch any issue via the `/estate-rollout` skill until lucas42 explicitly lifts the pause.

**Why:** lucas42 asked to pause on any estate rollout for now (no reason given). The instruction is open-ended — applies to all estate rollouts, not just one.

**How to apply:**
- When an `agent-approved` issue is marked as needing `/estate-rollout` (either by label, body text, or skill routing), do **not** dispatch it. Instead, leave it parked with `status:blocked` (reason: "estate rollouts paused by lucas42, see project memory") and tell the user it's parked.
- Specifically, `lucas42/lucos_repos#317` (the ADR-0005 follow-up to remove stale required CodeQL checks from infra-only repos) is the known queued rollout. Currently `status:blocked` on `#316`. Even after #316 merges, do **not** dispatch #317 — keep it blocked until the pause is lifted.
- When the pause is lifted: remove this memory file, drop the entry from MEMORY.md, and update any blocked rollout issues' labels.
