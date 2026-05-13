---
name: feedback_env_var_wiring
description: Three-stage env-var wiring requirement and naming conventions — learned from 2026-05-13 scheduled-jobs monitoring blackout
metadata:
  type: feedback
---

Every new environment variable requires three steps. Missing any one causes silent failures in production.

**Stage 1 — code reads it**: the application code reads the variable.
**Stage 2 — compose passes it through**: the variable is declared in `docker-compose.yml`'s `environment:` block so the container sees it.
**Stage 3 — lucos_creds stores the value**: the actual value is stored in lucos_creds for the relevant environments.

Doing only stage 1 (code) is the failure mode from the 2026-05-13 incident: inside the container the value was empty, the fetcher logged `{no_scheme}` warnings once per minute, and all scheduled-job monitoring went dark for ~7h 20m.

**Why:** Until lucas42/lucos_repos#387 (CI convention check) ships, there is no automated guard. It is on the implementer to wire all three stages.

**How to apply:** On every PR that introduces a new env var — before pushing — verify: (a) it's in the `environment:` block of docker-compose.yml, (b) a value has been written to lucos_creds (at least for `development`), (c) `.env.example` is updated if present.

---

**Env var naming convention:**
- `_ENDPOINT` suffix → holds the **full URL including path** (e.g. `https://host/report-status`)
- `_ORIGIN` suffix → holds **just the origin** (e.g. `https://host`)

Don't hard-code a path append on top of an `_ENDPOINT`-named variable. Pick the suffix that matches the value shape.

**Why:** Mixing these up (e.g. deriving a path from an `_ENDPOINT` variable) produces doubled paths or silent misrouting.

---

**Empty-string `getenv` defaults mask wiring failures.** A `getenv("X", "")` followed by an HTTP call fails quietly (`{no_scheme}` warnings) rather than crashing at startup. When designing how a missing-config case should behave, prefer a startup crash over silent degradation.

**Why:** Quiet warnings delay detection — the 7h 20m blackout was partly because no alert fired immediately.
