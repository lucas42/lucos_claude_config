---
name: reference-lucos-creds-ssh-auth-model
description: lucos_creds SSH/SFTP authorisation is per-KEY environment restriction only — no per-system or per-path ACL; docker-deploy is unrestricted, the agent sandbox key is limited to development,test
metadata:
  type: reference
---

Paths are `${system}/${environment}/${key}`; `environment` is a free-form string (`production`, `development`, but also `publish` for orb creds — it is not limited to deploy environments, and creating a new one is implicit in setting the first credential at it).

**Authorisation model** (`server/src/authorized_keys` + `isEnvironmentAllowed` in `server/src/server.go`, read 2026-08-31):
- Each `authorized_keys` line may carry a `restrict-environment="a,b"` option → `Permissions.Extensions["allowed-environment"]`.
- **Empty restriction = ALL environments allowed.** `isEnvironmentAllowed("", anything)` returns `true`.
- **There is NO per-system or per-path ACL.** Environment is the only dimension access is restricted on.
- `docker-deploy` (the CI key, fingerprint `b7:75:7e:64:66:44:40:06:95:b4:ad:cd:07:a7:6f:08`, registered on all lucos CircleCI projects) has **no** restriction → it can read any new `system/environment` path with **no server-side change**.
- `lucos-agent-coding-sandbox` has `restrict-environment="development,test"` → the "agents can only write development" rule is **enforced in code**, not just convention. An agent attempting another environment gets `Access to '<env>' environment is not permitted for this key`.

**How to apply:** when a new creds path is needed for CI, don't file it as "needs server-side authorisation config" — it's just "lucas42 sets two values". Hedge only that this is read from the repo, not the running server; drift shows up as an immediate visible fetch failure. Related: [[reference_lucos_creds_self_deploy]], [[pattern_three_stage_env_var_wiring]].
