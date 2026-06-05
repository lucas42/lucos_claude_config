---
name: pattern-creds-envrestrict-flaky-test
description: lucos_creds circleci alert from a failed `test` job = flaky TestEnvironmentRestrictedAccess scp assertion. Re-run the workflow; don't re-diagnose. Tracked in lucos_creds#358.
metadata:
  type: project
---

# lucos_creds `test` job flake → gated deploy (don't re-diagnose)

**Signature:** monitoring `circleci` check on lucos_creds goes red; CircleCI `build-deploy` workflow failed at the **`test`** job (build succeeds, `lucos/deploy-avalon` = `not_run`). A merged PR appears "not deployed". Failing test = `TestEnvironmentRestrictedAccess` (`server/src/server_test.go`), assertion on a *forbidden* scp read: expects `exit 255 + "/usr/bin/scp: Connection closed"`, gets `exit 1 + "lost connection"`.

**Root cause:** the assertion hard-codes a scp/OpenSSH-client exit code + error string that is version- AND CI-timing-dependent. NOT a product-code bug. Proven 2026-06-05: byte-identical pre/post the triggering PR (#354), passes 5/5 locally at the merge commit (OpenSSH 9.6p1 → exit 255/"Connection closed"), and **passed on a CI re-run with no code change**.

**Remediation:** re-run the workflow from failed (`POST /api/v2/workflow/{id}/rerun` `{"from_failed":true}` with `CIRCLECI_API_TOKEN`). `test` passes → serial group → `deploy-avalon` runs → PR ships. The deploy is gated `requires:[test, lucos/build]`, so a `test` flake silently blocks an already-merged PR.

**Don't chase the schema migration:** the `scope`-column migration is in-code (`ColumnExists`→add-column at startup in storage.go), runs when the server boots, logs `INFO Migrating table linked_credential: adding scope column`. It is NOT a CI deploy step and cannot fail a deploy job. Deploy verification: container on new image + `INFO Listening for connections address=[::]:2202` after the migration line + `/_info` ssh-server ok + monitoring healthy.

**Permanent fix tracked in lucos_creds#358** (test-only: assert non-zero exit + denied read, not the exact string). Until that merges, the flake can re-gate ANY lucos_creds merge — and lucos_creds is on the mandatory-security-review list, so it changes often. If #358 is still open when this recurs: just re-run, comment on #358, don't refile.
