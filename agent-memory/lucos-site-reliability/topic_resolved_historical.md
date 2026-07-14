---
name: resolved-historical
description: Second-level index of RESOLVED/benign patterns — fixed at source, closed, or self-resolving. Consult only if the symptom recurs; do not re-raise as new findings.
metadata:
  type: reference
---

Patterns whose root cause is **fixed at source, closed, or benign-by-design**. Kept for recurrence-checking, moved out of MEMORY.md's first-level index to keep it scannable. **If one of these symptoms reappears, read the file before assuming it's new — and check whether the original fix regressed.**

## Fixed at source / closed
- [linuxplayer phantom `?action=error` DELETEs](pattern_linuxplayer_phantom_error_deletes.md) — RESOLVED #123; re-open if recurs.
- [Incremental rsync: ProxyJump host-key + unquoted `rm&&mv`](pattern_incremental_rsync_container_proxyjump_hostkey.md) — RESOLVED; shlex.quote; `SHK=no` doesn't reach ProxyJump.
- [deploy-avalon exit 18 "pull access denied for *_test"](pattern_deploy_orb_pull_profile_blind.md) — orb pull profile-blind; FIXED in orb 0.0.185, needs a fresh pipeline to pick up.
- [Firewall enforce rollout](project_firewall_rollout.md) — COMPLETE 2026-06-08 (lucos#182). Durable bits: DRY_RUN override, Compose-reuses-stale-network foot-gun, host-net+router INPUT pattern.
- [Alert suppression asymmetric → orphaned "Everything OK" emails](pattern_monitoring_suppression_asymmetry.md) — #264.
- [backups create-backups red on empty (zero-commit) repo](pattern_backups_empty_repo_fails_run.md) — wget exit 8 on ref-less codeload; #298.
- [seinn playback-error thrash ≠ cache-eviction thrash](pattern_seinn_playback_thrash_distinct_from_cache_thrash.md) — decodeAudioData/fetch fails; #482 fixed #483.
- [media_import all_files red = weekly full scan hard-killed by redeploys](pattern_media_import_fullscan_killed_by_redeploy.md) — cron grandchild SIGKILLed; #173.

## Benign / self-resolving — do NOT open an issue
- [monitoring self fetch-info flap → ACCEPT, don't build](pattern_monitoring_self_fetchinfo_flap_accept.md) — global 1s timeout; #186 closed as accepted.
- [backup-without-original red forever on decommissioned system's retained backups](pattern_backups_without_original_on_decommission.md) — benign; fix = configy-absence signal (#359).
- [home-host backups red = ISP dropped upstream IPv6 transit](pattern_salvare_ipv6_prefix_withdrawal.md) — self-resolves; don't force IPv4.
- [lucos_repos audit mass 403s = GitHub secondary rate-limit](pattern_repos_audit_dryrun_secondary_ratelimit.md) — not lost access; non-incident.
- [MariaDB "closed normally without authentication" abort](pattern_mariadb_unauth_abort_is_nc_dbwait_probe.md) — linuxserver `nc` DB-wait probe; ~1/start; `host:` is the app's own IP.
- [lucos_creds `test` job flake gates deploy](pattern_creds_envrestrict_flaky_test.md) — flaky scp assertion; re-run from failed; #358.
