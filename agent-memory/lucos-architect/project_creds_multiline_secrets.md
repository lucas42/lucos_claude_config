---
name: creds-multiline-secrets
description: lucos_creds ADR-0006 — base64-at-rest for multi-line/key-typed secrets; the divergent-framing-guard + material-blindness pattern that generalises to any line-oriented secret transport
metadata:
  type: project
---

**lucos_creds ADR-0006** (PR lucas42/lucos_creds#484, Proposed, awaiting lucas42). Consolidated remediation from the **2026-07-19 configy_sync key-corruption incident** (source lucas42/lucos_creds#474; report in `lucas42/lucos/docs/incidents/2026-07-19-configy-sync-key-corruption.md`). Authored at lucos-site-reliability's request.

**Decision:** store multi-line / key-typed secrets (SSH keys, PEM) **base64-encoded at rest, decode at point of use**. A base64 blob has no semantic interior newlines, so it's single-line for the whole store→shell→container→disk transport — dissolving CRLF, header-truncation-at-newline, and `$(...)` trailing-strip at once. Pair with **type-aware material validation at decode** (`ssh-keygen`/`openssl`), replacing hand-rolled framing guards. Migration is **tolerant-read** (accept base64-or-raw → re-store the 2 keys → drop fallback), not flag-day.

**Precedent:** `LUCOS_DEPLOY_ENV_BASE64` already base64s the entire creds `.env` for exactly this reason — the estate accepts base64 as the tool for awkward bytes through a line-oriented channel. ADR-0006 applies it per-value.

## The reusable pattern (generalises past creds)

1. **Destination-side framing guards drift and are blind by construction.** The two consumers (`configy_sync/startup.sh` shell `case`; `ui/src/index.js validateSshKey()`) carried *duplicated, already-divergent* framing checks (UI checks a PEM footer the shell doesn't). **All 8 checks across both are framing-only**, so a full-length, LF-only, correctly-framed, one-byte-short (cryptographically invalid) key — the Round-2 corruption — passes every one. Adding a 9th guard can't fix a blindness defined by *what the checks are*, not how many. Smell: guard-accretion at the point of *observation* rather than the point of *corruption*.
2. **Transport-integrity and content-validity are different surfaces; neither closes the other.** base64 makes a *correct* value survive transit; validation rejects a *malformed* one. A fix touching only one leaves the other's gap. State this explicitly in any such design so "we added validation" isn't misread as closing the transport hole.
3. **Point-of-use vs store-side validation trade-off:** store-side *material* validation is the earliest catch but needs a **value-typing model** the store lacks (its `config`/`simple`/`client`/`server` types are about management, not value-schema). Point-of-use (consumer knows its own type) gets most of the benefit cheaply; store-side typed validation deferred, gated on introducing value-typing.

**Layer split vs lucas42/lucos_creds#473:** #473 = identifier validation + universal bare-CR/control-char reject at the **store write** (catches Round 1, no typing needed). ADR-0006 = transport + **material** validity. Complementary, no overlap. (#473 body was stale — name-only — until SRE reconciled it 2026-07-22 to match its scope-correction comment; decision-4's no-double-cover claim relies on the corrected shape.)

**Contributors folded in (credited by role, substance not verbatim):** type-aware validation dispatch — lucos-system-administrator; paste-time UI rejection message — lucos-ux; both raised during SRE's incident review.

**Deferred (commission separately once Accepted):** (1) creds impl + migration + lucas42 re-store of the 2 prod keys; (2) store-side typed-material-validation-if-value-typing question.

Related: [[creds-configy-sync]], [[reference_lucos_creds_deploy_snapshot]], [[feedback_new_validation_makes_existing_rows_unwritable]], [[feedback_flag_day_verification_gate]]
