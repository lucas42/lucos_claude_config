---
name: lucos-aithne-jsclient-adr-review
description: Security review of ADR-0001 for lucos_aithne_jsclient (shared JS verify/classify library) — three findings requested before merge
metadata:
  type: project
---

# lucos_aithne_jsclient ADR-0001 review (2026-07-10)

Reviewed lucas42/lucos_aithne_jsclient PR #1 (ADR-0001, founding design for a shared JS
library replacing four copy-pasted aithne token-verification modules — lucos_creds,
lucos_notes, lucos_media_seinn, lucos_loganne — per lucas42/lucos#264, following the
lucas42/lucos#260 audit). Posted **REQUEST_CHANGES**:
https://github.com/lucas42/lucos_aithne_jsclient/pull/1#pullrequestreview-4667690228

**Baseline confirmed sound** (cross-checked against `docs/local-verification-contract.md`
in lucos_aithne): ES256 hard pin, 30s clock skew, `aud`/`iss` checks, `AITHNE_JWKS_URL`
never touching the `iss` check, `isJWKSInfraError` narrowing (`error.cause?.code`,
excludes `ERR_JWKS_NO_MATCHING_KEY`), dev-only `render-ui` bypass, fail-closed posture
(`unavailable` → local error page, no access-granting branch).

## Three findings requested before merge

1. **`kid` log-injection not carried into the ADR (Medium).** Contract §2 (from
   lucas42/lucos_arachne#646) requires stripping C0 control chars + DEL from any
   `kid`-bearing string before logging — `kid` is attacker-controlled and jose embeds it
   verbatim in error messages. ADR's §4/§5 logging obligations don't mention this. The
   library's `Classification.error` (populated for `unauthenticated`/`unavailable`) is
   exactly the surface a consumer would naturally `.message`-log — a NEW gap the
   extraction would introduce, not an existing one it fixes. Check this got added when
   re-reviewing the updated ADR or the eventual v1 implementation PR.

2. **`loginUrl(returnUrl)` open-redirect guard left unenforced (Medium).** ADR framed
   same-origin validation as "documented but cannot enforce" — disagreed, jointly with
   lucos-code-reviewer (who raised it first). The library has its own `origin` config
   and receives the resolved `returnUrl` string — enough to reject/clamp non-same-origin
   values, same "origin-suffix check" pattern already accepted as sound for aithne's own
   `/auth/remint` CORS (ADR-0003 §2, see [[lucos-aithne-security-architecture]]).
   Recommended v1 scope, not deferred.

3. **`verifyToken()` skips the scope gate (Low-Medium, my own addition, not raised by
   code-reviewer).** `verifySession()` bakes in `requiredScope`; `verifyToken()` (used by
   `lucos_loganne`'s Bearer path and `lucos_notes`' WS handshake — the two most
   sensitive/least-human-observed consumers) does not. Risk: a migration PR treats
   `outcome: 'authorized'` from `verifyToken()` as "go ahead" without separately checking
   `payload.scopes` — recreating the exact "forgot the check in one of N places" pattern
   the whole library exists to retire. Recommended either extending `verifyToken()` with
   the same optional `requiredScope`/`authorize` param, or making the ADR explicit that
   `authorized` from `verifyToken()` means authenticated-only, with a shared `hasScope()`
   helper exported for consumers to call.

## What to check on re-review

When the ADR is updated (or if a v1 implementation PR lands before the ADR is amended),
verify these three landed — don't treat this as closed until confirmed in the actual
PR text, not just recalled from this memory. If lucos_loganne or lucos_notes migration
PRs land using `verifyToken()` without an explicit scope check, that's finding #3
materialising — flag it directly on that PR.

Related: [[lucos-aithne-security-architecture]] for the broader aithne security model.
