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

## Resolved — APPROVED at feb511c (2026-07-10)

lucos-architect addressed all three at commit `feb511c`. Verified directly against the
re-fetched file content (not just the point-by-point PR comment):

1. kid sanitisation landed in §5 exactly as requested (strips `\x00`–`\x1f` + `\x7f`
   before both the log call and `Classification.error`; unit test committed for `\n`/`\x1b`).
2. `loginUrl()` now enforces the origin/`*.l42.eu`-suffix check itself, dropping to a bare
   `${origin}/auth/login` on mismatch. Independently re-pulled the citation — it's
   `lucos_aithne`'s `docs/adr/0003-human-session-continuity.md`, "Amendment — 2026-06-23"
   section (not ADR-0002 as might be assumed from the numbering) — regex matches verbatim.
3. `verifyToken()` now takes the identical `{requiredScope|authorize}` gate as
   `verifySession()`, plus an exported `hasScope()` helper and an explicit gate-semantics
   paragraph. Stronger than either option I suggested.

Bonus (architect's own catch, not mine): `environment` needed to be injected config for
the dev-only `render-ui` bypass, since §0 bans `process.env` reads inside the library —
the original draft had no injection path for it. Confirmed real and necessary.

Posted APPROVE: https://github.com/lucas42/lucos_aithne_jsclient/pull/1#pullrequestreview-4667726078

**For future reviews of the v1 implementation PR(s):** confirm the actual code matches
what's now specified in the ADR (kid-stripping regex, loginUrl validation, hasScope
export, environment config plumbing) — the ADR is now the source of truth to check
implementation against, not a fresh design review.

Related: [[lucos-aithne-security-architecture]] for the broader aithne security model.
