---
name: lucos_creds deploy reads CI snapshot, not live store
description: When reasoning about lucos_creds deploys, remember the deploy reads LUCOS_DEPLOY_ENV_BASE64 from CircleCI (a manually-maintained snapshot) rather than the live creds.l42.eu store, due to the circular self-deploy dependency from lucos_creds#152
type: reference
---

## Fact

`lucos_creds` does **not** read its own `.env` from the live `creds.l42.eu` store at deploy time. Instead, the CircleCI deploy reads `LUCOS_DEPLOY_ENV_BASE64` — a base64-encoded snapshot of the `.env`, manually copied into a CircleCI env var.

This indirection exists to break the circular dependency identified in `lucas42/lucos_creds#152`: lucos_creds can't bootstrap itself by reading its own creds from the very service it provides.

## Architectural consequences

1. **Live-store fixes do not propagate on deploy.** Updating a credential via the lucos_creds_ui (or the API) updates the live store, but the next CircleCI deploy will overwrite `.env` from the stale snapshot. To make a fix actually stick, the snapshot **and** the live store must both be updated.

2. **The snapshot is hand-maintained.** It does not auto-sync. Any drift between live store and snapshot is silent until the next deploy.

3. **Generalised pattern: any service whose config provider depends on the service itself probably has a snapshot path.** When designing or reviewing deploy flows, look for `*_DEPLOY_*` / `*_ENV_BASE64` patterns. A one-line `grep` rules out the snapshot-indirection trap before it bites architectural reasoning.

## Diagnostic rule of thumb

When SRE reports "fix to live state didn't take after redeploy," **the first question is whether the deploy reads the live store or a snapshot**, not "did the live store actually update". Confidently blaming the live store as the cause without checking the deploy path is the failure mode that delayed recovery in the 2026-05-09 incident.

## Architectural follow-up

There is a deferred architectural item: **snapshot auto-sync** — eliminate the manual maintenance burden by having the snapshot regenerated from the live store as part of the deploy step (or pulled at runtime from a one-shot bootstrap path). lucas42 deferred this on cost grounds in the 2026-05-09 retrospective; SRE will surface it when the cost framing changes.

When that issue lands as `owner:lucos-architect`, the design space includes:

- Sync at deploy-time (CircleCI step that reads live store before building the deploy bundle — but this only works if the live store is reachable from CI, which has its own auth flow).
- Bootstrap-fetch at runtime (lucos_creds reads its own `.env` from a tiny bootstrap snapshot containing only the credentials needed to read the rest from itself; rest of `.env` populated at startup).
- Periodic sync via a cron in lucos_backups or similar (snapshot regenerated every N hours; deploy still reads CI var, but staleness window bounded).

Trade-offs to weigh: complexity of the bootstrap path, attack surface of any new auth flow that lets CI read live creds, recovery posture if the live store is itself broken at deploy time (the snapshot is a recovery path — auto-sync removes it).

## Framing for the deferred architectural item

When SRE files the snapshot-auto-sync issue, they will frame it as: *"lucas42 has deferred this for cost reasons; is there a low-cost variant, or close `not_planned`?"* — with **security's silent-rotation-revert framing as the cost-side counter-weight to consider** (i.e. the cost of *not* auto-syncing is that a credential rotation done in the live store can be silently reverted by the next deploy from the stale snapshot). Worth pulling up the security persona's framing of silent-rotation-revert risk when the issue lands, before forming a recommendation. Source: SRE SendMessage 2026-05-09 follow-up to creds incident broadcast.

## Provenance

- Foundational decision: `lucas42/lucos_creds#152` (circular dependency)
- Documented behaviour: `lucas42/lucos_creds#233`
- Failure-mode incident: 2026-05-09 (CRLF in stored SSH keys, recovery delayed by stale snapshot overwriting live-store fix). Report at `lucas42/lucos/docs/incidents/2026-05-09-creds-ssh-key-crlf.md`.
- Follow-up tickets: `lucas42/lucos_creds#304` (runbook), `#305` (UI warning), `#306` (startup validation).
