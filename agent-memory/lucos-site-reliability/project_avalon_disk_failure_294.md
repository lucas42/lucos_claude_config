---
name: project-avalon-disk-failure-294
description: RESOLVED 2026-09-16 — avalon's single disk failed 2026-09-14; data rescued to xwing+salvare and restored; estate verified end to end. Report lucas42/lucos#297 (draft). What's still out, what the rescue dir holds, and the privacy rule on it.
metadata:
  type: project
---

**RESOLVED 2026-09-16 03:39 UTC.** avalon's single non-RAID disk failed 2026-09-14 (~07:55 onset, host unmanageable 19:21). Data was rescued in OVH rescue mode, the host rebuilt on Debian trixie at the same IP, and the estate restored and verified. **Total ~1 day 20 hours.** Incident report: **lucas42/lucos#297**, still a **draft** — lucas42 and team-lead settle ready/review/merge. Source issue lucas42/lucos#294; rebuild runbook lucas42/lucos#296.

## Still out / still open

- **`lucos_mail_smtp` is down** — dovecot `Unsupported dovecot_storage_version 2.4` on an unchanged pre-incident image, so **the estate has no outbound email alerting**. lucas42/lucos_mail#79, Critical, sysadmin's.
- **The DNS secondary on xwing holds no zone files on disk** and served all five zones from memory for two days. lucas42/lucos_dns#135 — root cause NOT found; the four obvious explanations are ruled out in the issue.
- **lucas42/lucos_monitoring#313** — a check whose source disappears reads green, not unknown. Architect writing an ADR.
- Others: lucas42/lucos#299 (CI bootstrap, documentation-only, **owner me**), lucas42/lucos#301 (aurora recovery path, me), lucas42/lucos#302 (post-rebuild confirmations, me), lucas42/lucos#300/#303/#304 (lucas42), lucas42/lucos_monitoring#312, lucas42/lucos_media_linuxplayer#146, lucas42/lucos_backups#415 (mine, and now also carries the 72h create-backups threshold evidence).

## The rescue directory — ⚠️ privacy rule

`~lucos-agent/emergency-backups-2026-09-14/` on **xwing and salvare**, mode 700. `README.md` there is the restore guide. **Nothing is deleted yet** — lucas42's rule: not until the rebuild has bedded in, and a while beyond (lucas42/lucos#304, revisit from 2026-09-30).

- **A credential-exposure disposition decided 2026-09-15 lives ONLY in that README's "Deliberately NOT copied" section. Never restate it in memory, commits, issues, PRs or #297** — lucos_claude_config and lucos are PUBLIC.
- **Mode 700 is not the real boundary**: `lucos-agent` already has root-equivalent access on xwing and salvare via `docker` group membership (lucas42/lucos_agent_coding_sandbox#102). Standing access, not new exposure — but don't describe the permission bits as the control.
- **The rescued SSH host keys were never installed.** The rebuild generated fresh ones (the runbook's documented fallback), so those private keys are now the only copies of a host that no longer exists.

## Facts worth keeping

- **Access topology (verified 2026-09-16):** agents reach **avalon, xwing and salvare each directly** — `~/.ssh/config` has no `ProxyJump`/`ProxyCommand`. **aurora is the only host behind a gateway** (xwing). I asserted otherwise in a risk assessment and it was load-bearing; see [[reference_aurora_access_and_rsync]] for aurora's working recipe.
- **Verification that mattered** (see [[pattern_verifying_a_create_backups_run]]): the first triggered `create-backups` run **failed** with every one of `lucos_backups`' sixteen checks green; the second succeeded — **124 archives**, matching every pre-incident run. Data checked against the README's figures: contacts 30 tables, eolas 41, photos 7 + `vector`, media 14,755 tracks / 121,274 tags `integrity_check ok`, worlds' activity log to 2026-09-14 00:16:29 (lucas42's last edit, in no backup).
- **DNS deadline is no longer live**: the secondary re-established contact with the rebuilt primary at 00:37 on 2026-09-16 and all five serials match.
- **Deferred:** ops Checks 3 and 4 from 2026-09-14 were never run.
