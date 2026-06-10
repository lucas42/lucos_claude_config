---
name: aithne-autonomous-build
description: lucas42 authorised autonomous completion of the non-migration lucos_aithne build while away (2026-06-10)
metadata: 
  node_type: memory
  type: project
  originSessionId: bbdfac99-480d-4231-a8bc-48f76d9907fb
---

On 2026-06-10 lucas42 stepped away, authorising the team to implement **all open `lucos_aithne` tickets EXCEPT the migration (#12) and any post-migration tickets**, without him. `lucos_aithne` is unsupervised, so PRs auto-merge on `lucos-code-reviewer` + `lucos-security` approval (aithne is on the always-security-review list) — no lucas42 approval needed.

Standing permissions while away:
- Keep dispatching ready aithne tickets autonomously (don't wait for `/next` from lucas42).
- If the team raises **new** aithne tickets, dispatch them too — **unless** they are part of the migration or post-migration work.
- Any blocker that genuinely requires lucas42 (a change/approval on a **supervised** repo) → **set it aside**, continue with the unblocked parts.

Build order: #5 (session-token spine) → unblocks #6 (WebAuthn) + #8 (machine auth) → #10 (admin-invite, also needs #6). #9 (scope-grant authority) is independent and Ready. **#30/#31/#32** (security follow-ups raised from #5's review, 2026-06-10) are all **Blocked on #5**: #31 (key-rotation trigger, Medium) + #32 (JWKS Cache-Control, Low) are fully autonomous once #5 merges; #30 (encrypt signing key at rest, Medium) has a prod-KEK set-aside (below). When #5 merges, unblock #31/#32 to Ready/developer and dispatch.

Set-aside touchpoints (supervised repos — verified 2026-06-10) — items needing lucas42 on his return:
- ✅ **`SIGNING_KEK` randomly generated — CONFIRMED by lucas42 2026-06-10.** #30 KEK entropy assumption holds; no re-provisioning. Done.
- **#8** machine auth — the long-lived key lives in `lucos_creds` (supervised). aithne code ships autonomously; provisioning a **production** machine key in creds is lucas42-only → set that activation step aside.
- **#30** encrypt signing key at rest — **RESOLVED/CLEARED 2026-06-10 09:32Z:** lucas42 provisioned the KEK in `lucos_creds` (dev + prod, different value per env). **Env var is `SIGNING_KEK`** (NOT the `KEY_AITHNE_SIGNING_KEK` in the original body — body corrected; implement against `SIGNING_KEK`). #30 now unblocked → Ready/developer/Medium; dispatch after #31. (Implementation note for whoever reviews: there's 1 existing auto-gen *unencrypted* signing key in prod — the encryption rollout must handle migrating/rotating it; no real data lost either way per the earlier empty-DB check.)
- **#10** admin-invite — enrolee needs a `lucos_contacts` (supervised) entry. **RESOLVED 2026-06-10:** lucas42 pre-provisioned `KEY_LUCOS_CONTACTS` + `LUCOS_CONTACTS_ORIGIN` for aithne in lucos_creds (dev + prod) — so #10 can call the existing contacts API autonomously, no contacts code change. Relay lucas42's #10 comment (00:43Z) to the developer at #10 dispatch so they use those creds. Only re-flag to lucas42 if implementation finds the existing contacts API lacks a needed endpoint (would be a supervised code change).

## BOOTSTRAP_ADMIN_CONTACT_ID SET (2026-06-10) — security verdict: SAFE, no new attack surface
lucas42 set `BOOTSTRAP_ADMIN_CONTACT_ID` (dev+prod). Security assessed (full read on record): `bootstrapAdmin` runs at **startup** (creates principal + admin grant in DB; **no HTTP route, no conditional handler**). Resulting admin is **locked out** — `/admin/*` need the `aithne:admin` JWT → needs WebAuthn login → needs a registered passkey, which the bootstrap contact has zero of. Enrolment is invite-gated (122-bit single-use token, hashed; issuing invites needs the admin JWT). Chicken-and-egg = the security property. **No security action; #6 residual thread closed.**
Two operational notes (NOT security):
- **Bootstrap first-passkey enrolment — #48 DESIGN DONE 2026-06-10.** Architect designed + documented (security signed off). Artifacts: **ADR-0002** (`docs/adr/0002-bootstrapping-the-first-admin.md`) + runbook (`docs/runbooks/bootstrap-first-admin.md`) opened as **draft PR #50** pinging lucas42 — stays draft until **lucas42 signs off the design** (aithne unsupervised, but a new security-sensitive ADR is a lucas42 design gate). Impl ticket **#49** raised (board: Blocked / lucos-developer / Medium) — `--bootstrap-invite` docker-exec subcommand + `bootstrapAdmin` credential-existence self-disable gate + startup WARNING + **compose passthrough fix** (see below). lucos-security to review #49 code. **When lucas42 approves PR #50 + it merges → unblock #49 (Blocked→Ready, reposition Medium), dispatch to developer.** **Gates lucas42 actually administering aithne.**
- **INERT BOOTSTRAP (surface to lucas42):** `BOOTSTRAP_ADMIN_CONTACT_ID` is in dev+prod creds but **NOT** in aithne's `docker-compose.yml` `environment:` array, so it never reaches the container — the bootstrap is currently inert as deployed. The one-line compose passthrough is part of #49 (var is optional, safe for the dummy-PORT build).
- Minor runbook: the bootstrap grant re-runs every startup + is permanent (no self-disable). To revoke later: remove the env var AND revoke the DB grant.

## SECURITY ITEM — RESOLVED 2026-06-10 08:35Z (unauthenticated registration exposure)

**Closed:** #37 (REGISTRATION_ENABLED default-off → 503) merged 08:35Z with lucos-security + code-reviewer APPROVED — durable lockdown live, before the 22:16 nginx-block expiry. No exploitation occurred (verified empty DB), no incident, no lucas42 escalation needed. Interim nginx block on avalon now redundant (self-clears at 22:16 cron). #10 will later remove the endpoints entirely (the permanent fix). Detail below for history:

### Post-#40-merge follow-ups (when #10/PR#40 lands — security-approved 2026-06-10, awaiting code-reviewer final approve + auto-merge)
- #40 **removes** the 3 `/auth/register/*` endpoints + the `REGISTRATION_ENABLED` flag → gap permanently closed (no kill-switch needed after).
- ✅ url.PathEscape hardening ticket **filed as #42** (Ready/developer/Low).
- **`REGISTRATION_ENABLED` creds var:** harmless now (#40 removed the code that read it, so any orphaned var is inert). Tidy when convenient — dev clean is an agent/sysadmin job; if it was set in **prod** that's a lucas42-return cleanup. Low priority, not blocking.
- #10 closed 09:04Z (the permanent fix).
- nginx block already self-clears at 22:16Z.

### (history) unauthenticated registration exposure

`lucos-security` assessed #6's WebAuthn **registration endpoints** (live on aithne.l42.eu since #6/PR#36 auto-deployed ~02:25Z) as an **unacceptable live exposure**: unauthenticated → credential-squatting for any contact_id; **if `BOOTSTRAP_ADMIN_CONTACT_ID` is set in prod, attacker can register as admin = full compromise**. Security's preferred nginx block needs a `lucos_router` PR (SUPERVISED → lucas42, away). So using security's stated fallback: **lucas42/lucos_aithne#37 (Critical)** — `REGISTRATION_ENABLED` env flag default-off → 503 on `/auth/register/*`; aithne unsupervised → auto-merges+deploys; dispatched to developer AHEAD of #10. #10 then removes the endpoints (durable fix; UX scoped the removal in).

**De-escalated 2026-06-10 — NOT an incident, no lucas42 escalation.** Security checked prod directly: `BOOTSTRAP_ADMIN_CONTACT_ID` NOT set (worst case unachievable); DB empty (0 principals/credentials/grants, 1 auto-gen signing key); zero requests to `/auth/register/*` in the window. No exploitation occurred, blast radius ~zero. #37 still proceeds as a **precautionary** lockdown (close the known gap before #10) — security fast-tracking its review. No need to interrupt lucas42's break.

Interim bridge: sysadmin left a **live nginx block on avalon** (host-level, not the supervised router PR #96 which was closed; branch `security/block-aithne-register` preserved for defence-in-depth when lucas42's back). That live block is **overwritten by the 22:16 UTC router cron** — so **#37 must land before 22:16 UTC** to keep the gap closed (easily met: Critical/tiny/fast-tracked, ~20h out). If #37 somehow stalls past 22:16, the gap reopens (though blast radius is ~zero per the empty DB).

**Why:** protects the authorisation against context compression during the away-period, so the build keeps moving and I don't wrongly pause to ask an absent lucas42. **How to apply:** dispatch ready aithne tickets as they unblock; only pause the specific supervised-repo sub-steps above. Retire this memory when lucas42 returns / the non-migration build is complete. Related: [[project_firewall_rollout]] pattern of an autonomous estate build.
