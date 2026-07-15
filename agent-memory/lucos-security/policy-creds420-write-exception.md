---
name: policy-creds420-write-exception
description: lucos_creds#420 Option 5 — narrow dev→prod :write exception approved for fb_import/gphotos_import contacts writes, with exact mechanism signed off
metadata:
  type: project
---

**Decision (2026-07-09):** lucas42 chose Option 5 on lucas42/lucos_creds#420 — a narrow, vetted `lucos_creds` dev→prod `:write` exception — over building an aithne CLI-auth feature (2b) or routing through human tokens (2a). Reasoning: no more CLI scripts are moving to aithne tokens (he dislikes the style for new work), and the two importers needing this are both on a deprecation glide path, so a whole feature isn't justified.

**Who it covers (verify against the ticket before reusing — do not assume this list grows):**
- `lucos_contacts_fb_import` (dev-only, no prod instance)
- `lucos_contacts_gphotos_import` (dev-only, no prod instance)
- Both link to `lucos_contacts` production, scope `contacts:write` only.
- **`lucos_contacts_googlesync_import` is explicitly NOT part of this exception** — it already has a prod instance and gets `contacts:write` via the normal prod→prod path. A teammate's dispatch summary named googlesync_import instead of gphotos_import in the initial ask — caught and corrected before sign-off; the ticket's own text ("facebook... google photos...") is the authoritative source, not any relayed summary.

**Mechanism I signed off on:** a hardcoded, compiled-in Go allowlist in `lucos_creds` `scopes.go` (not an env var, not a DB row, not API-settable) keyed on the exact 4-tuple (client_system, client_environment, server_system, server_environment) + exact scope string, checked as a narrow override inside the existing `allScopesReadOnly` guard (`storage.go:378-388`). Plus a unit test asserting the allowlist's *exact* contents (not just non-empty), so any future addition is a visible, reviewed diff. See `storage.go`/`scopes.go` as read 2026-07-09 for the guard's current shape.

**Why this is a materially different case from the aithne-OIDC dev-credential rejections** (see [[policy-dev-prod-credential-containment]]): those were rejected because the OIDC client secret is authenticated by hash and scope enforcement never actually gated the flow — a scoped link was security theatre. Here, `lucos_contacts`' scope enforcement is real and per-request server-side (already proven live for `googlesync_import`'s `contacts:write`), so narrowing the scope on this credential genuinely narrows what a leaked copy can do. **Don't assume this precedent transfers** — before treating any other creds-link scope as a real risk reducer, verify the resource server actually enforces link-level scope on the flow in question, the same way I verified it here before signing off.

**Open item at sign-off time:** `fb_import`'s half of the exception may be inert — it still authenticates with the legacy `Authorization: key` prefix and `lucos_contacts`'s `api_auth` is Bearer-only. The ticket believed lucas42/lucos#74 covered fb_import's migration; it turned out to be docs-only. Filed lucas42/lucos_contacts_fb_import#52 to track the actual migration-or-retire decision. Check that issue's state before assuming fb_import's write exception is live/exercised.

**Conditions attached:** scope ceiling is `contacts:write` only (no future broadening without fresh sign-off); tie removal of each allowlist entry to the importer's actual decommission/migration (gphotos_import → lucOS photos migration completion; fb_import → lucas42/lucos_contacts_fb_import#52 resolution).

**Update 2026-07-15 — both halves of the deprecation-tie-in condition are now discharged/tracked:**
- **fb_import: discharged by decommission, not migration.** lucas42/lucos_contacts_fb_import#52 closed `not_planned` — lucas42 chose to decommission the repo outright rather than migrate to Bearer (archival tracked lucas42/lucos#271). creds#420's body was updated so the allowlist ships with **exactly one entry** (gphotos_import only); fb_import's entry is dead-on-arrival and never gets implemented, so there's nothing to remove later.
- **gphotos_import: still live, now has its own dated tripwire ticket** — lucas42/lucos_creds#468 (filed by me, on the board, not yet triaged). Don't assume this is actionable: it's gated on the lucOS photos migration (lucas42/lucos_photos#424 / #427) landing AND lucas42 confirming gphotos_import is no longer run. Suggested Status = Blocked/blocked-by #427, Priority = Low. This is the concrete lesson behind the "conditions attached" line above — a sign-off condition with no separately-tracked follow-up ticket is invisible once the original ticket (#420) closes; always spin the removal checkpoint into its own issue rather than trusting it'll be remembered from the sign-off comment alone.
