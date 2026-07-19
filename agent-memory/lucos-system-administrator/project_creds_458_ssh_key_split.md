---
name: project-creds-458-ssh-key-split
description: lucos_creds#458 shared-SSH-key split — Ready, assigned to me, ordering constraints for prod rotation
metadata:
  type: project
---

`lucas42/lucos_creds#458` (shared SSH key differentiated-grant split) moved from Ideation to **Status = Ready, Owner = lucos-system-administrator, Priority = Medium** on 2026-07-13, after ADR-0004 (PR #457) merged 2026-07-12 accepting the differentiated-grant model. `lucas42/lucos_creds#459` is explicitly Blocked-on-#458 — this key split is the prerequisite that unblocks it.

**Why:** ADR-0004 settled the design; #458 is now the implementation ticket, and #459 can't proceed until the key differentiation exists.

**How to apply:** When this reaches me via `/next`:
- The **production** secret rotation in `lucos_creds` is lucas42-only (agents never write non-dev creds) — do not attempt it myself.
- Prod rotation must be **coordinated**: the `authorized_keys` change and the production creds rotation need to converge together (client+server), same pattern as other `lucos_creds` key-rotation work — see [[lucos-creds-circleci-env-vars]] and the general "rotation causes a convergence window" lesson.
- The dev-side keypair regen + `authorized_keys` change **can** be built and PR'd ahead of the prod rotation — that part isn't gated on lucas42.
- Issue body already has a Decision section (per team-lead, 2026-07-13) with the ⚠️ manual-step flagged — read it fresh when picking this up rather than relying on this summary.

**Status (2026-07-19): implemented, PR open.** Re-keyed `lucos_creds_configy_sync` only (left `lucos_creds_ui` untouched); wrote the new private key to the `development` `CONFIGY_SYNC_PRIVATE_SSH_KEY` secret via the standard SSH-exec-write pattern from `~/.claude/references/github-app-secrets-provisioning.md` — that reference's "preserves real embedded newlines" guidance applies equally to a raw ed25519 private key, not just GitHub App PEMs. Verified with a round-trip `scp` fetch + byte comparison against the generated key (matched, modulo the `.env` file's own trailing newline) before deleting the local key material. PR https://github.com/lucas42/lucos_creds/pull/471 — approved by lucos-code-reviewer and lucos-security, awaiting lucas42 (supervised repo, merge gate) plus his prod secret rotation + configy_sync redeploy. lucos_creds#459 (scope grants) stays blocked until this merges.
