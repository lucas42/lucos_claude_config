---
name: pattern-baseimage-bump-runtime-break
description: Auto-merged base-image bump breaks at deploy/runtime (not build) → red main + service down
metadata:
  type: project
---

**Red `main` pipeline right after an auto-merged Dependabot base-image bump = a RUNTIME/deploy failure, not a build failure.** `apk add`/package installs succeed at build; the breakage only surfaces when the daemon starts at deploy. So the bump passes the build-gated auto-merge and ships a latent runtime break.

**Diagnostic order:** workflow → jobs. If `lucos/build` = success and `lucos/deploy-<host>` = failed, it's runtime. Read the deploy step log (it shows the healthcheck/container failing), then SSH the host and read the *container* logs for the real fatal error. Don't reason from the build.

**Confirmed instance (2026-06-11, lucos_mail):** Dependabot #58 bumped `postfix/Dockerfile` `alpine:3.21.1 → 3.24.0`. Alpine 3.22+ ships **Dovecot 2.4**, which requires `dovecot_config_version` as the FIRST setting in `dovecot.conf` (`doveconf: Fatal: … The first setting must be dovecot_config_version`). Old config → dovecot crash-loops → `lucos_mail_smtp` healthcheck (`nc -z 127.0.0.1 25`) fails → mail down ~14 min. Restored by rerunning last-green pipeline (#146) then pinning alpine back (PR #59). Fix-forward = Dovecot 2.4 config migration (lucos_mail#60). Incident: `lucos/docs/incidents/2026-06-11-mail-alpine-dovecot24-outage.md`.

**Restore playbook for a base-bump outage:** (1) cancel queued reruns of the broken pipeline (`POST /api/v2/workflow/{id}/cancel`) so they stop redeploying the broken image — but first verify you're not orphaning the estate-wide avalon deploy lock (check Loganne: are other avalon deploys still landing?). (2) Restore by rerunning the last-GREEN pipeline (`POST /api/v2/workflow/{id}/rerun` `{"from_failed":false}`) — clean redeploy via the normal path. **Don't hand-roll the container** (no persistent compose on hosts; stateful volumes like mail-data risk loss). (3) Pin the base back via a one-line PR for durable green main. (4) File fix-forward issue + incident report.

**Recurrence trap:** repos with `dependabot-auto-merge.yml` will RE-OPEN and RE-MERGE the same base bump on the next daily run → re-break on a timer. The pin alone doesn't hold.

**The durable fix is a CI TEST JOB, not a Dependabot ignore and not "gate on deploy"** (lucas42's framing, 2026-06-11; he reframed my initial take). The real gap: the repo had no test that *starts the stack*, so nothing between merge and prod ran the daemon. A test that boots the stack fails in CI on the broken bump and **blocks the auto-merge outright** — cleaner than special-casing deploy-gating, and it removes the recurrence risk without any ignore. So: propose/await a stack-startup test (lucos_mail#61) as the fix-forward; reach for a temporary `ignore` only as a last-resort stopgap if the test can't land before the next daily Dependabot run (and even then it's the owner's call — I opened ignore PR #62, team-lead had me close it as superseded by the test job). Don't lead with "auto-merge should gate on deploy" — lead with "add a test that asserts the stack comes up."

**Monitoring gap this exposed:** **lucos_mail has NO smtp/port-25 probe** — checks are tls/fetch-info/circleci/apache (all docs-side). A full mail outage is invisible to monitoring except as a red `circleci` check (a CI signal, not "mail down"). Weigh a synthetic-mail check vs its hygiene/config cost before building.
