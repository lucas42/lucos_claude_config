---
name: feedback-migration-scope-matches-spec
description: "When briefing a teammate to apply a spec / pass a convention / fulfil a rollout, the brief's scope must match the spec's scope — no belt-and-braces adjacent checks"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1d8b0493-7b56-4592-950d-0bfb7fba2120
---

When briefing a teammate to apply a spec, pass a new convention check, or carry out an estate-rollout migration, the brief must cover **only** what the spec / convention / rollout requires. Adjacent checks that *might* be prudent but are not part of the originating spec are scope-creep and don't belong in the brief.

**Why:** On 2026-05-16, while briefing `lucos-system-administrator` for the `env_var_passthrough` estate-rollout migration, I added a "critical pre-step: verify lucos_creds has the values" with an extensive rationale tying it back to the 2026-05-13 monitoring blackout. But the convention is narrowly scoped — it checks code reads vs `docker-compose.yml` passthrough declarations only. It does NOT check lucos_creds. The migration's job is to make the convention check pass; adding lucos_creds verification was me deciding to enforce a broader invariant the convention deliberately doesn't enforce. Lucas42 caught it: "Why is sysadmin checking what's in lucos_creds? I thought the convention check is just about what's set in docker-compose.yml?"

**The reasoning that misled me:** "If we just add compose entries without verifying lucos_creds, the apps could silently break in the exact way the convention is designed to prevent." That sounds prudent but is wrong because: (a) the deployed apps are currently working with the existing compose state, so values must already be set; (b) adding a passthrough entry where lucos_creds is missing is at-worst a no-op (compose forwards empty, code reads empty — same as today); (c) if we wanted broader checks, they should live in the convention, not in ad-hoc migration prudence.

**How to apply:**

Before sending a brief that contains adjacent steps the originating spec didn't require, ask: *is this step needed for the spec/convention/rollout to pass?* If no, cut it. Specifically:
- "Critical pre-step" / "Make sure to also check…" framings are red flags — they signal I'm enriching the brief beyond its spec.
- The originating spec (architect's design comment, convention definition, rollout-issue body) is the authoritative scope. Quote from it; don't add to it.
- If I genuinely think the spec is too narrow, the right move is to flag that to the architect / user and ask whether the spec should expand — not to silently broaden the migration brief.

See also [[feedback-audit-architecture]] (audit-tool functionality is intentional) and [[feedback-scope-checks-belong-to-reviewer]] (PR scope policing is the reviewer's job).
