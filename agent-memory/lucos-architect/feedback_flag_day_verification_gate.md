---
name: feedback-flag-day-verification-gate
description: When an ADR's roll-out plan has two cutovers that must happen together (a flag-day), specify a verification gate between them — not just the order
metadata:
  type: feedback
---

When an ADR's roll-out plan involves two (or more) cutovers that must land together — a "flag-day" — the migration section must specify **both** the order **and** a verification gate between them. Specifying only the order is not enough: PRs land minutes apart, deploys happen automatically, and there is no human-in-the-loop checkpoint to confirm Stage N is actually healthy before Stage N+1 ships.

**Why:** ADR-0004's flag-day cutover (lucos_monitoring's new fetcher + lucos_schedule_tracker dropping `/_info` checks) landed ~25 minutes apart. The new fetcher was silently broken (empty env var, `{no_scheme}` warnings every 60s), and the simultaneous `/_info` cutover meant every scheduled-job check disappeared from monitoring estate-wide for ~7h 20m. The ADR specified the order (fetcher first, then `/_info` cutover) but didn't specify a gate. Reference: `lucos/docs/incidents/2026-05-13-scheduled-jobs-monitoring-blackout.md`, Stage 1 of the analysis.

**How to apply:** In any ADR migration section with a flag-day, write the gate as an explicit step. Examples of good gate language:

- "Before step N+1, confirm `curl https://monitoring.l42.eu/api/status | jq '...'` shows the new checks present."
- "Step N must include a verification command that exits non-zero if the new state isn't observable; step N+1 must not start until that command passes."
- "Step N+1 is blocked by step N's deploy completing AND a human (or CI job) confirming the verification command in step N succeeds."

The gate is most useful when it can be expressed as a single shell command or HTTP request that returns the new state — that way the gate works equally well for a manual cutover or an automated rollout. Vague "verify it's working" language is too easy to skip under time pressure.

Watch for this whenever an ADR migration section has the shape "after this lands, do that". If the two cutovers cannot easily be combined into a single PR (different repos, different deploy units, etc.), they need a gate.

**Related — the failure SIGNATURE of a creds key-rotation/scope-change cutover is 403, not 401.** A `lucos_creds` linked-credential scope change *rotates the key value* (ADR-0003 immutable-scope-per-key: unconditional regenerate, `UNIQUE` link → no overlap → hard cutover). The consumer holding the **pre-rotation key** is rejected — and in services using the `api_auth`/`getUserByKey` Bearer pattern (lucos_contacts, etc.) an **unrecognised key returns 403, not 401** (`else: return 403`). So during a scope-rotation rollout a 403 spike is the *expected* convergence signature, NOT evidence of a missing grant/scope. Don't predict 401 (I did, on the contacts Wave 4 cutover 2026-06-28, and had to self-correct). **Decision test when consumers 403 mid-rollout:** read the *server's deployed* `CLIENT_KEYS` directly (`docker exec <svc> printenv CLIENT_KEYS`, mask values) — if the consumer's entry is **present + scoped**, it's pure key-mismatch and the fix is to **redeploy the consumer** onto its rotated key (no creds/prod action); if **absent**, it genuinely needs the key/scope added in prod creds. Both look identical as a 403 from the outside — only the deployed CLIENT_KEYS distinguishes them.
