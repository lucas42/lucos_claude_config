---
name: lucos-creds-scoped-key-permissions
description: lucos_creds CLIENT_KEYS scope design (lucos_creds#87); ADR-0004 deny-by-default allow-scopes redesign (lucos_creds#457); lucos_creds_ui architecture and the shared-SSH-key finding (lucos_creds#458)
metadata:
  type: project
---

# Structural fact: no agent SSH key can ever read production values

Every agent (any persona) authenticates to `lucos_creds` as the same shared
`lucos-agent-coding-sandbox` key (`~/.ssh/id_ed25519_lucos_agent`, `Host creds.l42.eu` in
`~/.ssh/config`), `restrict-environment="development,test"`. Verified live 2026-07-19:
`ssh -p 2202 creds.l42.eu "ls lucos_creds/production"` → *"Access to `production` environment
is not permitted for this key"*. **This means any claim resting on "production data looks like
X" cannot be independently verified by lucos-security, lucos-code-reviewer, lucos-architect, or
any other persona — all agents share this identical wall.** When a PR/ADR's load-bearing
evidence is dev-only by necessity (e.g. lucos_creds#472's "no origin-less system is a link
target" claim), say so plainly rather than implying a second agent's review adds reach it
doesn't have — only lucas42 can close a production-only verification gap.

**Plaintext-origin estate scan (2026-07-19, development only):** pulled every readable
system's `development/.env` (48 of 50 listed systems — 2 malformed store entries skipped,
`set lucos_notes`/`write lucos_notes`, tracked as ADR-0005 deferred cleanup) and grepped for
`http://` pointing at a non-local, non-internal host. Found exactly **one** — the already-known,
already-filed `TIME_API="http://am.l42.eu"` (lucas42/lucos_media_weightings#268, Ready/Low).
No other instance across the reachable estate. Production is not covered (see above) — this
result is development-only and shouldn't be read as an estate-wide clearance. Re-run rather
than trust this as a standing fact if asked again after significant time has passed (drift).

# Design: lucos_creds scoped key permissions (lucos_creds#87, approved 2026-03-13)

`CLIENT_KEYS` format extended with `|` delimiter for optional scopes:
```
clientsystem:clientenv=key|scope1,scope2
```
Unscoped entries unchanged. Scopes only set after the server is migrated (deploy first,
set scopes second — env vars pulled at deployment time is the natural safety checkpoint).

Key security decisions accepted:
- **No scope = no permissions** (fail-closed by default on migrated systems)
- Scope enforcement is server-side only; client never knows its own scopes
- Scopes opaque to lucos_creds; each service defines its own vocabulary (`{resource}:{action}`)
- Loganne audit trail for scope changes included
- Scope-aware flag rejected — migration risk accepted given deployment-time env var pull

Do not re-raise the scope-aware flag concern.

# Risk: LUCOS_DEPLOY_ENV_BASE64 silently reverts credential rotations

`lucos_creds` bootstraps its own deploy from a manually-maintained base64 snapshot
stored as a CircleCI env var (`LUCOS_DEPLOY_ENV_BASE64`), which overwrites the
production `.env` on every redeploy.

**A credential rotation applied only to the live lucos_creds store silently fails to
take effect.** The deploy writes `.env` from the stale snapshot, not the live store —
the running service never sees the new value, at any point, unless
`LUCOS_DEPLOY_ENV_BASE64` is also updated. Affected credentials (lucos_creds's own
`.env`, not creds it stores for others):
- `UI_PRIVATE_SSH_KEY`, `CONFIGY_SYNC_PRIVATE_SSH_KEY`, `KEY_LUCOS_CREDS` (the most
  sensitive cryptographic material in the estate — a silently-reverted rotation of
  `KEY_LUCOS_CREDS` is the worst case)

**Status (2026-05-09):** Runbook in lucos_creds#304 should include the explicit
callout that rotating any credential present in `LUCOS_DEPLOY_ENV_BASE64` without also
updating the CircleCI env var silently undoes the rotation on next deploy.
Architectural auto-sync deferred (cost). lucos_creds#306 adds startup validation of SSH
key material.

# Architecture: lucos_creds has an HTTP-facing human UI, not just the SSH server

`lucos_creds` repo has a `ui/` directory (`ui/src/index.js`, an Express app) — a real,
deployed, human-facing admin console, distinct from the SSH/SFTP server that's the
primary access surface for other systems. Easy to forget/omit when reasoning about
"the whole attack surface" (an ADR draft did exactly this, lucos_creds#457, corrected
2026-07-12 — see [[lesson-verify-real-client-behavior]] pattern: always grep for a
`ui/` dir before accepting an "SSH-only, no HTTP surface" claim about this repo).

- Gated by **one aithne scope**: `ui/src/auth.js` `REQUIRED_SCOPE = 'creds:admin'` — no
  metadata-vs-secret split, no read-vs-write split. Anyone holding `creds:admin` gets
  full view+edit of every credential in every system/environment through the UI.
- The UI backend talks to the SSH server as its own dedicated identity, `lucos_creds_ui`
  (`ui/ssh-config`), keyed by `UI_PRIVATE_SSH_KEY`.
- `creds:admin` in `scopes.yaml` is documented as covering *both* meanings (an "admin
  console" comment) — i.e. the one scope token does double duty for what could be two
  different admin postures (metadata-browse vs secret-edit). Not a problem after
  ADR-0004 (below) — flag only if a future scope-vocabulary cleanup pass touches it.

# ADR-0004: deny-by-default `allow-scopes` access control (lucos_creds#457, Accepted 2026-07-12)

Replaces the single `restrict-environment` allow-by-default axis with **deny-by-default,
scope-based grants**. Went through two full redesign rounds during review — durable
shape and the lessons from getting there:

**Final model:**
- One `authorized_keys` option, `allow-scopes`, e.g.
  `allow-scopes="creds:metadata:read@*; creds:secret:read@development; creds:write@development"`.
  Grants are `<scope>@<environment-set>`, `;`-separated; `@*` is the environment wildcard.
  Replaces the two-axis (`restrict-environment` + a would-be second option) design from
  round 1 — a single option sidesteps a real bug I found in that design: `parseAuthorizedKeys`
  builds `permissions.Extensions` as a full map *replacement* per matched option, not a merge,
  so two options on one key would have let whichever parsed last silently clobber the other's
  restriction (fails **open**, since both axes default-allow). One option, one extension key,
  makes that bug structurally impossible rather than something to test around.
- **Deny-by-default**: absence of a grant is denial, full stop. A new key with no
  `allow-scopes` gets nothing (fails loudly), reversing the old `restrict-environment`
  default-allow footgun.
- Three granular scopes (`creds:metadata:read`, `creds:secret:read`, `creds:write`, added to
  the shared `lucos_auth_scopes` vocabulary) plus **`creds:admin` as a fixed, named
  full-access grant — not a wildcard**. `creds:admin` satisfies every scope check today
  (metadata+secret+write) but does **not** auto-absorb any scope added to creds in future;
  each new scope is a deliberate include/exclude decision.
- **UI-consistency resolution (§6):** the UI keeps its single `creds:admin` aithne check
  unchanged; consistency with the SSH-key axis comes from granting the UI's own
  `UI_PRIVATE_SSH_KEY` exactly `creds:admin@*` — same token, both planes. This is *not*
  scope decomposition of the UI (that was rejected as unneeded complexity) — it's making
  the one check on each plane agree. One accepted asymmetry: environment-scoping is a
  machine-key tool only, since aithne JWTs have no environment concept, so a human via the
  UI is not environment-scoped even though an agent SSH key can be.
- **Migration is flag-day, one repo, five keys** (`lucas`, `docker-deploy`, `lucos_creds_ui`,
  `lucos_creds_configy_sync`, `lucos-agent-coding-sandbox` — the whole committed
  `authorized_keys` file, checked directly against `main`). All five must get explicit
  grants in the *same* PR that flips enforcement on, or every `.env` deploy-time fetch
  breaks instantly.

**Migration-table corrections I caught by reading the actual client code (worth the
habit — don't trust a table marked "(confirm)" without doing the confirming):**
- `lucos_creds_configy_sync` (`configy_sync/sync.py`) calls the 3-part `ls` (secret:read)
  before every write and touches both `development` and `production` — an early draft
  proposed write-only, which would have broken its first sync run on flag day.

**Finding [lucas42/lucos_creds#458](https://github.com/lucas42/lucos_creds/issues/458) — CLOSED via PR #471 (2026-07-19):**
`lucos_creds_ui` and `lucos_creds_configy_sync` registered **byte-identical SSH public keys**
in the committed `authorized_keys` (confirmed directly, not inferred). Inert under the old
allow-by-default model (both were unrestricted anyway) but would have become a real hole the
moment ADR-0004's differentiated grants land — whoever holds either private key can just claim
the other's username and get its (possibly more privileged) grant. lucos-code-reviewer found
this independently and filed #458. PR #471 minted a fresh, distinct ed25519 keypair for
`configy_sync` only, leaving `ui` untouched. I independently re-derived both pubkeys from the
dev creds store private keys (`ssh-keygen -y`) and confirmed the diff matches, confirmed no
key material leaked into the commit, and confirmed nothing else in the lucas42 org
(GitHub code search) pins the old shared key value. ADR-0004 §5 cited this as a hard
precondition for the deny-by-default flip — now satisfied.

**Why `configy_sync` (not `ui`) was the right one to re-key:** `docker-compose.yml` confirms
`lucos_creds`, `lucos_creds_ui`, and `lucos_creds_configy_sync` are three independently
deployed containers. `ui` is the human-facing admin console (aithne `creds:admin` scope,
full read+write of every credential) — high blast radius, interactively used. `configy_sync`
is a bounded, non-interactive cron container. Rotating the lower-blast-radius automated
identity rather than the admin console humans actually depend on is the safer choice whenever
a similar "which of two identities to re-key" question comes up on this repo.

**`configy_sync`'s prod-rotation convergence window is low-severity, verified from source —
not the same shape as the aithne KEK-derivation race:** `configy_sync/sync.py` runs on a cron
(hourly, `53 * * * *`), not any other service's live request path; each SSH call just
logs+raises on auth failure and the next hourly run tries fresh (cron doesn't track prior
exit codes); writes are idempotent/read-before-write so a missed run can't corrupt state,
only delay it; nothing else in the estate consumes its output live (see [[creds-configy-sync]]
— written values are only read by other systems at *their own* deploy time); `startup.sh`
re-derives the private key from the env var fresh on every container boot, so the very next
`lucos_creds_configy_sync` redeploy (not an estate-wide one) converges it. Contrast with the
aithne KEK race, which gated live JWT verification across ~20 interdependent consumers and
cascaded into a 46-min outage. **Pattern for future lucos_creds key-rotation PRs:** don't
accept a "self-heals" claim on faith — trace whether the credential gates a live request
path (aithne-KEK-shaped, high severity) or a bounded idempotent batch job with no live
consumer (configy_sync-shaped, low severity) before judging the convergence-window risk.
