---
name: Estate rollouts paused
description: User has paused all estate rollouts; do not dispatch via /estate-rollout until explicitly lifted
type: project
originSessionId: bda02c7e-0672-4d9e-8bc3-b7999c4c89e8
---
**Estate rollouts are paused as of 2026-04-10.** Do not dispatch any issue via the `/estate-rollout` skill until lucas42 explicitly lifts the pause.

**Why:** lucas42 asked to pause estate rollouts so they could read the ADR-0005 follow-up issues raised by the architect. After reading them, lucas42 identified a process misunderstanding: the architect had split a single rollout into two separate issues (`lucos_repos#316` for the convention + `lucos_repos#317` for the migration), when the correct pattern is one issue routed via `/estate-rollout` from the start with the convention as a draft PR. The pause remains in place pending further direction.

**How to apply:**
- When an `agent-approved` issue is marked as needing `/estate-rollout` (either by label, body text, or skill routing), do **not** dispatch it. Instead, leave it parked with `status:blocked` (reason: "estate rollouts paused by lucas42, see project memory") and tell the user it's parked.
- Specifically, `lucas42/lucos_repos#317` (the ADR-0005 follow-up to remove stale required CodeQL checks from infra-only repos) is parked. The convention itself (`#316` / `#318`) was merged before the pause was identified — that's done. The rollout `#317` remains blocked.
- When the pause is lifted: remove this memory file, drop the entry from MEMORY.md, and update any blocked rollout issues' labels.

**Authorised exceptions (option-3 individual handling, 2026-04-10):** lucas42 has authorised handling the 2 known offenders from the prematurely-merged `no-stale-codeql-requirement-on-infra-repos` convention (`lucas42/lucos_configy` with stale `Analyze (rust)`, and `lucas42/lukeblaney_blog` with stale `Analyze (javascript)`) as individual sysadmin tasks rather than via `/estate-rollout`. Each gets its own audit-finding issue when the next sweep raises it; each is dispatched independently via `/dispatch` to `lucos-system-administrator`. Once both are merged, close `lucos_repos#317` as completed-by-individual-fixes. **This authorisation is scoped to just these 2 specific repos and the specific convention** — it does not unblock any other rollout.
