---
name: creds-origin-envvars
description: lucos_creds ADR-0005 — deriving ORIGIN_<SERVERSYSTEM> from linked credentials; the ~19% zoo-migration ceiling and the link-vs-dependency boundary
metadata:
  type: project
---

**lucos_creds ADR-0005** (PR lucas42/lucos_creds#472, issue #470). Emit `ORIGIN_<SERVERSYSTEM>` alongside `KEY_<SERVERSYSTEM>` from each `linked_credential` row, so an origin and its key cannot disagree.

**Why:** two bugs with identical symptoms and opposite fixes — lucos_media_weightings#267 (re-point the origin) vs lucos_time#330 (re-link the credential). Deriving both from one row makes the divergence *unexpressible*, removing the "which half is wrong?" question.

**lucas42's direction (2026-07-19):** name `ORIGIN_<SERVERSYSTEM>`; uneditable in UI; block links to origin-less systems with an error naming the missing configy field; **configy↔creds sync must stay asynchronous** (a configy outage must not block link create/read/delete/rotate).

**Decisions worth remembering:**
- Origin derives from the link row's **`serverenvironment`**, never the client's own env (dev→prod links are legitimate).
- New synced per-system `INTERNAL_ORIGIN` ≠ `APP_ORIGIN` — see [[creds-configy-sync]] for why the latter isn't reusable.
- **Emitted `ORIGIN_*` must NOT be type `config`.** `cleanupRemovedSystems` enumerates type-`config` creds for systems absent from configy and calls `updateCredential(...,None)` → `normaliseCredentialKey` → would reject the reserved `ORIGIN_` prefix → sync aborts. `KEY_*` escapes this only by being type `client`.
- Blocking rule validates against **creds' own store, never a live configy call** — that's what reconciles lucas42's block-the-link and keep-it-async directives. The naive "ask configy" implementation violates the second.
- **Test envs carved out** of the blocking rule: `sync.py` only iterates dev/prod, so applying the block literally would make every test link illegal and remove the `test`→`test` linked credential that ADR-0002 recommends for holding a test secret.

**The finding that most qualifies the proposal: only ~19% of the origin "zoo" can ever migrate** (13 of 66 origin-shaped dev vars are backed by a link). Unmigratable: `lucos_aithne` (20, OIDC/JWKS needs no client key), `lucos_schedule_tracker` (15, not a link target), `lucos_loganne` (13). **General rule: the set of systems whose origin a client needs is much larger than the set it holds a key for** — most inter-system dependencies aren't key-authenticated. A linked credential is the right carrier only where a key and an origin must agree; broader origin config is a *dependency-modelling* problem (overlaps `lucos_repos` ADR-0006 C4 work).

**Also corrected here:** the "scope trap" (re-link to prod → silently grants dev write access to prod) is **closed** by ADR-0003's dev→prod read-only guard in `updateLinkedCredential`. Don't repeat the claim that it's open. Pre-ADR-0003 rows unaudited.

Related: [[creds-configy-sync]], [[creds-client-keys-environment-model]], [[creds-test-environments]], [[feedback_server_reachability_not_user_reachability]]
