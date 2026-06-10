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

**Why:** protects the authorisation against context compression during the away-period, so the build keeps moving and I don't wrongly pause to ask an absent lucas42. **How to apply:** dispatch ready aithne tickets as they unblock; only pause the specific supervised-repo sub-steps above. Retire this memory when lucas42 returns / the non-migration build is complete. Related: [[project_firewall_rollout]] pattern of an autonomous estate build.
