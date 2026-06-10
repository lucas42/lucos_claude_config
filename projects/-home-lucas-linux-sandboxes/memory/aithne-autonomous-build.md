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
- **#8** machine auth — the long-lived key lives in `lucos_creds` (supervised). aithne code ships autonomously; provisioning a **production** machine key in creds is lucas42-only → set that activation step aside.
- **#30** encrypt signing key at rest — needs `KEY_AITHNE_SIGNING_KEK` in `lucos_creds`. Dev KEK an agent can provision; **prod KEK is lucas42-only**, and prod encryption-at-rest needs it before deploy → set the prod activation aside. (Blocked on #5 first.)
- **#10** admin-invite — enrolee needs a `lucos_contacts` (supervised) entry. **RESOLVED 2026-06-10:** lucas42 pre-provisioned `KEY_LUCOS_CONTACTS` + `LUCOS_CONTACTS_ORIGIN` for aithne in lucos_creds (dev + prod) — so #10 can call the existing contacts API autonomously, no contacts code change. Relay lucas42's #10 comment (00:43Z) to the developer at #10 dispatch so they use those creds. Only re-flag to lucas42 if implementation finds the existing contacts API lacks a needed endpoint (would be a supervised code change).

## SECURITY ITEM — RESOLVED 2026-06-10 08:35Z (unauthenticated registration exposure)

**Closed:** #37 (REGISTRATION_ENABLED default-off → 503) merged 08:35Z with lucos-security + code-reviewer APPROVED — durable lockdown live, before the 22:16 nginx-block expiry. No exploitation occurred (verified empty DB), no incident, no lucas42 escalation needed. Interim nginx block on avalon now redundant (self-clears at 22:16 cron). #10 will later remove the endpoints entirely (the permanent fix). Detail below for history:

### Post-#40-merge follow-ups (when #10/PR#40 lands — security-approved 2026-06-10, awaiting code-reviewer final approve + auto-merge)
- #40 **removes** the 3 `/auth/register/*` endpoints + the `REGISTRATION_ENABLED` flag → gap permanently closed (no kill-switch needed after).
- **File a hardening ticket** (autonomous, Low) for security's minor observation: `url.PathEscape()` missing on `contact_id` in aithne's contacts HTTP client (admin-only, no real attack surface).
- **Verify no orphaned `REGISTRATION_ENABLED` creds var** (dev/prod) — #37 used a code default, so likely none was set, but confirm nothing's left dangling.
- nginx block already self-clears at 22:16Z.

### (history) unauthenticated registration exposure

`lucos-security` assessed #6's WebAuthn **registration endpoints** (live on aithne.l42.eu since #6/PR#36 auto-deployed ~02:25Z) as an **unacceptable live exposure**: unauthenticated → credential-squatting for any contact_id; **if `BOOTSTRAP_ADMIN_CONTACT_ID` is set in prod, attacker can register as admin = full compromise**. Security's preferred nginx block needs a `lucos_router` PR (SUPERVISED → lucas42, away). So using security's stated fallback: **lucas42/lucos_aithne#37 (Critical)** — `REGISTRATION_ENABLED` env flag default-off → 503 on `/auth/register/*`; aithne unsupervised → auto-merges+deploys; dispatched to developer AHEAD of #10. #10 then removes the endpoints (durable fix; UX scoped the removal in).

**De-escalated 2026-06-10 — NOT an incident, no lucas42 escalation.** Security checked prod directly: `BOOTSTRAP_ADMIN_CONTACT_ID` NOT set (worst case unachievable); DB empty (0 principals/credentials/grants, 1 auto-gen signing key); zero requests to `/auth/register/*` in the window. No exploitation occurred, blast radius ~zero. #37 still proceeds as a **precautionary** lockdown (close the known gap before #10) — security fast-tracking its review. No need to interrupt lucas42's break.

Interim bridge: sysadmin left a **live nginx block on avalon** (host-level, not the supervised router PR #96 which was closed; branch `security/block-aithne-register` preserved for defence-in-depth when lucas42's back). That live block is **overwritten by the 22:16 UTC router cron** — so **#37 must land before 22:16 UTC** to keep the gap closed (easily met: Critical/tiny/fast-tracked, ~20h out). If #37 somehow stalls past 22:16, the gap reopens (though blast radius is ~zero per the empty DB).

**Why:** protects the authorisation against context compression during the away-period, so the build keeps moving and I don't wrongly pause to ask an absent lucas42. **How to apply:** dispatch ready aithne tickets as they unblock; only pause the specific supervised-repo sub-steps above. Retire this memory when lucas42 returns / the non-migration build is complete. Related: [[project_firewall_rollout]] pattern of an autonomous estate build.
