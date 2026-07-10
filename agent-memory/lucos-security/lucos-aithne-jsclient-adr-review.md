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

## v1 implementation reviewed and APPROVED (PR #6, ae8ff03, 2026-07-10)

Read the actual code (`index.js`, `index.test.js`, `.circleci/config.yml`,
`package.json`), not just the PR description. All three ADR items confirmed correctly
implemented AND tested against real behaviour, not mocked assertions:

- **ES256 pin** is a hardcoded literal in `classify()`, not consumer-configurable. The
  RS256-rejection test signs a real token and routes it through actual `jose.jwtVerify`
  (via the `_setVerifier` seam), not a stub that just checks the option was passed —
  genuine defence-in-depth test, not tautological.
- **`isJWKSInfraError`** dual-shape check (`error.code` / `error.cause?.code`) has a
  dedicated test for the exact native-`fetch`-wrapped `TypeError('fetch failed', {cause})`
  shape.
- **`kid` sanitisation** strips control chars from the *whole* error message (broader/
  safer than surgically targeting just the kid substring) — test embeds `\n`/`\x1b`/`\x7f`
  in a fake kid, confirms stripped while surrounding text survives.
- **`loginUrl()` guard** (`isTrustedReturnUrl`): parses with `new URL()` (defeats
  userinfo/backslash/scheme tricks), checks `.origin` against an anchored `*.l42.eu`
  suffix regex. Hand-traced bypass attempts (substring-not-suffix e.g.
  `l42.eu.evil.com`, malformed input) — all correctly rejected, fails safe to a bare
  login URL, never redirects to an untrusted destination.
- **`verifyToken()`** confirmed to funnel through the same `classify()` as
  `verifySession()` — single shared code path, not just matching signatures.
- **Bonus, implementer's own catch (not mine):** CircleCI `release-npm` now `requires:
  [test]` — the scaffold had published to npm on every `main` push with no test gate.

**One non-blocking observation logged on the PR, not a finding:** `isTrustedReturnUrl`'s
exact-match branch compares `returnUrl` against *aithne's own* configured `origin`, not
the calling consumer's origin (which the library never receives) — inert in practice
(fully subsumed by the `*.l42.eu` suffix regex), but the naming could mislead a future
maintainer into thinking it does more than it does. Not asking for a change.

Posted APPROVE: https://github.com/lucas42/lucos_aithne_jsclient/pull/6#pullrequestreview-4669851042

**Pattern for future reviews of this library/its consumers:** when a design doc gets
implemented, re-derive the security properties from the actual code paths (trace what
calls what) and check tests exercise real behaviour (real crypto, real error shapes)
rather than asserting against mocks that just confirm the code called the right function
name. This caught nothing wrong here, but is the check that would have caught it if the
implementation had drifted from the approved design.

## lucos-code-reviewer's PR #6 findings + `_setVerifier` risk question (2026-07-10)

lucos-code-reviewer reviewed the same PR in parallel and found two legitimate small bugs
(`sanitiseError()` dropped `error.cause?.code`, so `Classification.error.code` came back
`undefined` for the wrapped-`TypeError` shape even though `outcome` correctly read
`unavailable`; and no regression test for the `jwksUrl` ≠ `origin` invariant). Both fixed
by lucos-developer in commit `cc2933f` before I'd even finished writing my response —
verified the diff directly: `sanitiseError` now falls back to `error.cause?.code`
symmetrically with `isJWKSInfraError`'s own check, and the two new tests are genuine
(the negative case signs a real token with `setIssuer()` on the `jwksUrl` origin and
confirms it's rejected — not tautological). **Lesson: PR heads move fast when multiple
reviewers are active in parallel — my first APPROVE (`ae8ff03`) went stale within the
same review pass; always re-check `pulls/N.head.sha` before/after posting and re-approve
on the current head if it moved.** Re-approved at `cc2933f`:
https://github.com/lucas42/lucos_aithne_jsclient/pull/6#pullrequestreview-4669885546

**`_setVerifier` runtime-setter question — my verdict: not a materially new risk, worth
hardening, not worth blocking.** lucos-code-reviewer asked whether centralising the
`_setVerifier`/`_verifyFn` test seam (already present, unchanged, in all four legacy
consumer modules) into one shared library — now imported identically by four production
services — changes the risk calculus enough to want construction-time-only injection
(no public runtime setter) instead. My reasoning: anyone with enough in-process access to
grab a live client instance and call `_setVerifier` already has equivalent power to
monkey-patch `jose`'s own exported `jwtVerify` directly, or monkey-patch this library's
own `createAithneClient` export — both strictly more general bypasses available to the
same attacker tier regardless of whether `_setVerifier` exists, so it doesn't unlock a
materially new capability for a sophisticated supply-chain attacker. The more realistic
risk is an **accidental** one: a test-utils/global-setup module leaking into a production
import path and silently disabling auth via a stray `_setVerifier` call — a genuine
footgun class, and construction-time-only injection would close it for free at near-zero
cost. Recommended it as a cheap hardening (same "fix cheap while it's one place" logic as
the ADR's other two fixes) but explicitly left it as a should-fix/fast-follow, not a
blocker — posted as a COMMENT-type review, verdict (APPROVE) unchanged:
https://github.com/lucas42/lucos_aithne_jsclient/pull/6#pullrequestreview-4669881568

**If `_setVerifier` hardening lands in a later PR, verify it actually removes the public
runtime setter** (not just adds a config-time alternative alongside it, which would leave
the footgun in place) before treating this as closed.

### CLOSED — `_setVerifier` hardening landed and verified (PR #12, lucos_aithne_jsclient#7, 2026-07-10)

Confirmed it's a genuine removal, not an alongside addition: `_verifyFn` is now a `const`
closure capture (`config._verifyFn ?? default`), and the returned client object no longer
has a `_setVerifier` key at all — read the object literal directly, not just the PR
description. Went further than the code-level check: grepped all 4 known consumers
(creds/notes/seinn/loganne) for `_setVerifier` usage and confirmed every call site is a
test-only wrapper or test file (loganne's `__tests__/websocket.js` calls it directly in
`beforeEach`/`afterEach`, still test-only) — nothing calls it on a live request path, so
the failure mode on a future un-updated consumer adoption is a loud test-suite `TypeError`,
not a silently-disabled auth check. Two non-blocking notes left on the PR: no dedicated
regression test proves `_setVerifier` is absent (object-literal diff is sufficient proof
today), and each consumer will need a companion PR to update their own wrapper when
adopting — same explicit-PR-per-consumer pattern as the `appOrigin` rollout.

Posted APPROVE: https://github.com/lucas42/lucos_aithne_jsclient/pull/12#pullrequestreview-4671099712

## First consumer migration reviewed: lucos_creds PR #451, APPROVED (2026-07-10)

lucos-code-reviewer pulled me in (lucos_creds is on their mandatory always-security-review
list). Verified npm-pinned `1.1.0` (package-lock integrity hash) resolves to `346b03b`
(tag `v1.1.0`), whose last commit is `cc2933f` — exactly the commit already approved above.
Confirmed no unreviewed change had landed on the library between my approval and this
consumer adopting it — worth re-checking this each time a *new* consumer PR pins a
version, in case the library's `main` moved in between.

Confirmed the `loginUrl()` open-redirect fix is real for a consumer (not just in the
library's own tests): old `auth.js` fed `${req.protocol}://${req.headers.host}${req.originalUrl}`
straight into the redirect with zero validation (CWE-601 if `Host`/`X-Forwarded-Host` was
ever attacker-reachable — didn't confirm exploitability in lucos_creds' actual prod proxy
config, but the fix is unconditional either way). Also confirmed the `unavailable`→redirect
collapse isn't a new behaviour change in this consumer — the pre-adoption code already fell
through to the same redirect for JWKS infra failures, so "no local unavailable page" was
already this repo's status quo, just now delegated. Cross-checked lucas42/lucos#260's
reassessment thread directly (not the PR body's paraphrase) — his actual words: "I agree
with 'Abandon per-consumer local pages'".

**New non-blocking pattern to watch across the other 3 planned migrations (lucos_notes,
lucos_media_seinn, lucos_loganne — lucas42/lucos#264):** `middleware()` in this consumer
collapsed `console.warn('JWKS infrastructure error...')` vs `console.error('JWT
verification failed...')` into a single `console.error` for both `unavailable` and generic
`unauthenticated`-with-error. Not a vulnerability, but an alerting-signal regression — ops
loses the ability to distinguish "aithne is down" from "routine bad token" in logs. Check
each consumer migration PR preserves (or deliberately drops, with a stated reason) that
log-level distinction — `classification.error.code` is available for it, it's a one-line
fix in the consumer's own `middleware()`, not a library change.

Posted APPROVE: https://github.com/lucas42/lucos_creds/pull/451#pullrequestreview-4670146151

## `appOrigin` fix for the dead same-origin check (PR #10, lucos_aithne_jsclient#8, 2026-07-10)

My own "non-blocking observation" from the PR #6 review (above) turned out to be a real
functional bug, not just a naming nit: `isTrustedReturnUrl`'s exact-match branch compared
`returnUrl` against **aithne's own** `origin`, which a consumer's return URL practically
never equals — dead code in production, and in dev it meant a `localhost:<port>` consumer
never got `next=` embedded, so dev login never redirected back to the app
(lucas42/lucos_aithne_jsclient#8).

Fix: new opt-in `appOrigin` config field — the consumer's own origin, explicitly injected
by the consumer from its own `process.env.APP_ORIGIN` (never read from `process.env` by
the library itself, per ADR-0001 §0) — trusted in `isTrustedReturnUrl` alongside the
existing `*.l42.eu` suffix rule. Verified end-to-end by reading the full `index.js` at the
PR head:

- `appOrigin` is used in exactly one place; `issuer` and all JWT-verification paths derive
  solely from `origin`, untouched — this doesn't weaken token validation, only the
  return-URL allowlist.
- Comparison is exact `url.origin === appOrigin` equality (atomic scheme://host:port), no
  prefix/substring bypass.
- Opt-in is proven by a real negative-path test (no `appOrigin` configured → localhost
  returnUrl still dropped), not just asserted in prose.
- `appOrigin` is consumer-supplied at construction time, never attacker-influenced — the
  attacker only controls `returnUrl`, the thing being checked.
- Bounded blast radius even on operator misconfig: `loginUrl()` always redirects to
  aithne's own real login page; `appOrigin`/suffix rule only gate the `next=` param, and
  aithne's `/auth/remint` independently re-validates the same return URL server-side too
  (ADR-0003 Amendment 2026-06-23) — defence-in-depth, not the sole gate.

**Non-blocking residual noted on the PR, not asked to be fixed:** unlike the `*.l42.eu`
suffix regex (hard-requires `https://`), the `appOrigin` exact-match doesn't enforce a
scheme — an operator who misconfigures `appOrigin` as `http://` in production would have
that trusted as a plaintext return target. Low realistic risk (operator-controlled, and
`APP_ORIGIN` is a TLS-terminated public origin by estate convention) — suggested an
optional README caveat, didn't block on it. Worth checking if picked up in a fast-follow.

Scope note: this PR is library-only — the four existing consumers (creds/notes/seinn/
loganne) don't pass `appOrigin` yet and will each need a follow-up PR + version bump before
dev login is actually fixed for them. Watch for those migration PRs to confirm `appOrigin:
process.env.APP_ORIGIN` actually lands, not just the version bump.

Posted APPROVE: https://github.com/lucas42/lucos_aithne_jsclient/pull/10#pullrequestreview-4670959347

### Rollout complete — all 4 consumers (2026-07-10)

- **lucos_creds PR #453** — always-review repo, my sign-off required. Traced the full
  chain of custody rather than trusting the PR body: `v1.1.1` tag → merge commit `d84c2aed`
  → parent `114d0027` (exactly the PR #10 commit approved above, confirmed via the
  `compare` API, not assumed). Also confirmed `appOrigin` resolves to `https://creds.l42.eu`
  in prod, which was already inside the `*.l42.eu` suffix rule pre-change — so it's a
  redundant trust entry in prod, not a new one; the fix is genuinely dev-only as claimed.
  APPROVED: https://github.com/lucas42/lucos_creds/pull/453#pullrequestreview-4671043690
- **lucos_notes #464, lucos_media_seinn #559, lucos_loganne #568** — none on the
  always-review list, code-reviewer approved all three solo (no security sign-off
  requested or needed). For loganne specifically, code-reviewer confirmed the Bearer/
  `CLIENT_KEYS` machine-auth path is untouched by the `appOrigin` config addition — I have
  not independently verified that claim myself, noting per hedge convention.

All 4 planned migrations from lucas42/lucos#264 are now approved; last three awaiting
lucas42's merge (creds already merged, supervised repo). No outstanding security action
on this thread.

## The consumer-level `_setVerifier` migration re-opens the same footgun one layer up (2026-07-10)

lucos_creds PR #455 migrated `ui/src/auth.js` off the library's now-removed `_setVerifier`
(v1.1.2, the PR #12 fix above) by changing the module-level `aithne` binding from `const`
to `let` and having its own `_setVerifier(fn)` reconstruct the client
(`aithne = createAithneClient({...AITHNE_CONFIG, _verifyFn: fn})`) instead of mutating a
field. code-reviewer asked directly whether this reintroduces the risk #7 closed, one layer
up. **My verdict: yes, but it's not a regression** — diffed against the pre-#455 auth.js
(already read during #453): the unconditional, no-env-gate `_setVerifier` export already
existed at the consumer layer before this PR, already reachable from the same module as
production `middleware()`. The library-level fix (#7/#12) only closed the door at the
library; every consumer independently re-opened an equivalent door at their own layer to
keep their test API working — pre-existing, not new, low-likelihood (requires an in-process
bundling/import mistake, not externally reachable) but high-impact if triggered (silent
full auth bypass).

**Filed lucas42/lucos#268** proposing the same fix one layer up: a `createAuthMiddleware
(config)` factory per consumer instead of a mutable module-level singleton, so test and
production instances never share state. Flagged as Open Questions (not asserted Ready):
sequencing against the 3 remaining migrations, and the exact factory shape per consumer's
`index.js` wiring. Both are sequencing/design calls for lucas42/architect. Approved
lucos_creds#455 as-is (correct, minimal, urgent unblock — the next Dependabot bump would
otherwise red this service's CI per lucos_creds#454) — the issue is about the pattern, not
that PR.

APPROVED: https://github.com/lucas42/lucos_creds/pull/455#pullrequestreview-4671168804
Follow-up: https://github.com/lucas42/lucos/issues/268

**Two identifier mistakes caught in this thread, both worth carrying forward as one habit:
verify what a cited number actually IS (issue vs. PR, exists vs. guessed) before publishing
it, not after.**
1. Cited the follow-up issue number in the PR #455 review *before* creating it (guessed
   #267, real number was #268) — corrected via `PUT .../reviews/{id}`. File first, cite
   after; don't pre-guess sequential IDs.
2. The issue body originally cited `lucos_notes#465` / `lucos_media_seinn#560` /
   `lucos_loganne#569` as if they were the anticipated migration PRs. code-reviewer checked
   before relaying and found all three are open **tracking issues** (same shape as
   lucos_creds#454, which #455 implemented) — no migration PR exists for any of them yet.
   Corrected the issue body via PATCH. Lesson: a GitHub number is only as trustworthy as the
   fetch that confirmed what it points to — `is_pr` via `.pull_request != null` on the
   issues endpoint is the cheap check, and I should have run it before writing the number
   into a public issue rather than assuming "the migration ticket" meant "the migration PR."

**Watch when the 3 remaining migrations land:** check whether lucas42/lucos#268 got
resolved (or explicitly deferred) before notes/seinn/loganne copy the same
reconstruct-a-singleton shape as #455 — if it wasn't, that's 3 more instances of the same
accepted-but-flagged risk, worth noting in each review rather than re-litigating from
scratch.

Related: [[lucos-aithne-security-architecture]] for the broader aithne security model.
