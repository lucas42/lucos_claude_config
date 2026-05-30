---
name: pattern-monitoring-suppression-asymmetry
description: Orphaned "Everything OK" monitoring emails — alert suppression silences the failing email but not the recovery email
metadata:
  type: project
---

# lucos_monitoring: alert suppression is asymmetric (orphaned "Everything OK" emails)

**Symptom:** "Everything OK on X" emails with NO preceding "Monitoring issue on X" email. First reported by lucas42 2026-05-30 (3 in one day: media_metadata_manager, media_weightings, media_metadata_api).

**Root cause:** Suppression (deploy-window OR `dependsOn` dependency suppression) emits the *failing* alert with `suppressed => true` → `email.erl` drops it (no email) but the failing state IS cached. The subsequent *recovery* fires through `state_change/3`'s no-active-suppression branch as `notify_all(failing_checks => #{}, suppressed => false)` → `email.erl` sends it → `getFailCountSummary(0,…)` renders "Everything OK on X." So: failure cached-but-never-emailed → recovery emailed → orphan.

**Diagnostic signature (avalon `docker logs lucos_monitoring`):** a `suppressed via dependency` or `Alert suppressed … during deploy window` line for system X, then minutes later `Checks' state changed for X` + `Send notifications for X` with NO emailed alert in between. The `Send notifications for ~p` log fires on EVERY email actually sent (alert or recovery) — grep it to enumerate what went out. `email.erl`'s only drop-clause is `suppressed := true`; everything else emails.

**Why it surfaced ~late-Apr/May 2026:** asymmetry latent since dependency suppression landed (2026-04-14) but only bites checks declaring `dependsOn`. Those rolled out across media stack: metadata_manager 04-14, weightings upstream-probe checks 04-30. Polymorphic-dependsOn (#227, 05-12) NOT implicated — single-string decls preserved.

**Tracked in [lucas42/lucos_monitoring#264](https://github.com/lucas42/lucos_monitoring/issues/264).** If orphaned "Everything OK" emails recur before #264 ships, do NOT re-investigate — comment on #264. Fix direction: emit recovery email only if a corresponding alert was actually emailed (per-system "alerted" flag, or carry "was suppressed" through to recovery so it goes out suppressed=true → Loganne keeps it, email drops it). NB email.erl's header comment falsely claims recoveries are already dropped.
