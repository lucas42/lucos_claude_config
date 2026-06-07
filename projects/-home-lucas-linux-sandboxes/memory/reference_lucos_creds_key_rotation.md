---
name: reference-lucos-creds-key-rotation
description: lucos_creds rotates the key on every linked-credential update — scope/cred changes need coordinated redeploys
metadata: 
  node_type: memory
  type: reference
  originSessionId: 16ce3bf0-42eb-451d-97cf-044b4c07b46a
---

Updating a linked credential in lucos_creds **rotates the key on every update** — `updateLinkedCredential` (server/src/storage.go) calls `generateNewEncryptedValue` unconditionally, even when only the `scope` changes. So adding/changing a scope annotation changes the underlying key value for both sides.

**Operational implication:** any scope annotation or linked-credential change requires coordinated redeploys of *all* affected client services AND the server service so they converge on the new key. Expect a transient 401/403 window during convergence (a service that redeployed onto the new key calls the server while the server is still on its old `CLIENT_KEYS`, or vice versa). This is **not** the "annotate first, harmless, no coordination needed" pattern that older triage notes assumed.

**Proven rollout sequence** (eolas#286/#298 + creds#348, and media_metadata_api#300/#315, both 2026-06-07, converged with zero *standing* 403s):
1. lucas42 applies the production creds scope annotations (production creds writes are lucas42-only) — this rotates the keys.
2. Trigger CircleCI redeploys of all client services, **concurrent with** the server's scope-enforcement-code deploy (the enforcement PR merge), so all sides pick up new keys together.
3. SRE arms a convergence watch: monitor all pipelines + inter-service auth, confirm the transient 401/403 window closes at server cutover, and positively verify the write/POST paths from log evidence (Go services like eolas/mma don't log requests — verify via the shared lucos_router access log, and catch organic writes rather than injecting synthetic production data).

**Loganne auditing of scope changes:** `updateLinkedCredential` emits TWO events — a client-side `KEY_<SERVER_SYSTEM>` event that **carries the scope value** (use this to audit/verify a scope), and a server-side `CLIENT_KEYS` event that does **not** (compound credential). See [[reference-loganne-access]] equivalent in lucos-security's notes.
