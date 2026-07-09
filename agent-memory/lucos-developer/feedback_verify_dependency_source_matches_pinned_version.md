---
name: feedback-verify-dependency-source-matches-pinned-version
description: When reading a dependency's source to verify a behavior claim, confirm the installed version matches what the project actually pins — don't trust whatever happens to be on the host Python/Node's general site-packages
metadata:
  type: feedback
---

Before citing a dependency's source code as evidence for a behavior claim (e.g. "library X does Y on failure"), confirm the version you're reading matches the version the *target project* actually pins — not whatever's already installed in the host environment's general-purpose site-packages/node_modules. A stale or different-version install can sit on the host from unrelated prior work and silently produce the wrong answer with full confidence.

**Why:** claimed PyJWT's `PyJWKClient.fetch_data()` wipes its cache on a failed fetch (`finally: self.jwk_set_cache.put(jwk_set)` with `jwk_set=None`) as justification for a fix on lucos_photos#455/PR #465. This was true — but only for PyJWT 2.11.0, which happened to be installed on the host Python. The project actually pins `PyJWT[crypto]>=2.13.0`, and 2.13.0 fixed that exact self-wipe as a security patch (GHSA-fhv5-28vv-h8m8) — the real 2.13.0 `fetch_data()` only writes to the cache on the success path. lucos-code-reviewer caught the discrepancy by installing the actual pinned version fresh and reading its source. The underlying fix was still correct (an independent, non-expiring snapshot is needed regardless, because the parent cache's TTL still expires by time alone) — but the docstring's stated *reason* was wrong, and had to be corrected in a follow-up commit plus a correction comment on the issue.

**How to apply:** when verifying a dependency's runtime behavior to justify a fix or write in a PR/issue as fact, install the dependency fresh (e.g. `docker run --rm <lang-image> bash -c "pip install '<pinned-spec>' && python3 -c '...'"` or an equivalent throwaway venv) matching the exact version constraint from the project's manifest (`requirements.txt`, `package.json`, `Pipfile`, etc.), rather than checking `sys.modules`/`site-packages` on the host machine. This is the same discipline as [[feedback_verify_before_propagating]] applied to third-party library internals, not just first-party identifiers.
