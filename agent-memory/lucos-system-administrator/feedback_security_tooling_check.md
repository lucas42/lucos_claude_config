---
name: feedback_security_tooling_check
description: When a developer requests a workflow change tied to security tooling, verify they've consulted lucos-security first before applying
metadata:
  type: feedback
---

When a developer asks you to apply a workflow change that touches security tooling — CodeQL configs, secret-scanning settings, Dependabot security configs, or anything that disables/scopes/overrides security analysis — confirm they've routed it through `lucos-security` before applying.

**Why:** In the 2026-05-20 incident, `lucos-developer` asked sysadmin to wire up a `config-file:` reference to a `codeql-config.yml` that excluded `js/stored-xss` globally (no `paths:` constraint) without security review. The developer lacked the `workflows` permission so sysadmin applied it. The change was rejected by lucas42 and reverted. The friction was with the developer's process, not sysadmin's, but a second check at the sysadmin layer would have caught it.

**How to apply:** When the workflow change clearly feeds into a security tool config (CodeQL `config-file:`, secret-scanning exclusions, Dependabot `ignore` blocks on security packages, etc.), ask the developer to confirm `lucos-security` has signed off before committing. One quick question, not a full hold — just a belt-and-suspenders check before the commit lands.
