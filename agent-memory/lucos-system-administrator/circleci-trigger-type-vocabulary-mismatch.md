---
name: circleci-trigger-type-vocabulary-mismatch
description: CircleCI's REST API pipeline.trigger.type field and the config-compile-time << pipeline.trigger.type >> pipeline value use DIFFERENT string vocabularies for the same trigger
metadata:
  type: reference
---

`lucos_agent`#72: RESOLVED 2026-09-01, PR #84 + #86. `prune-images`'s scheduled workflow never ran for 3+ months because `when: equal: [scheduled_pipeline, << pipeline.trigger.type >>]` compared against the wrong vocabulary.

**The gotcha, empirically confirmed (not just from docs):** CircleCI's REST API (`GET /pipeline`) reports a scheduled pipeline's `trigger.type` as `"scheduled_pipeline"`. But the config-compile-time pipeline value `<< pipeline.trigger.type >>` — evaluated inside `.circleci/config.yml`'s own `when:` blocks — uses a **different string**: `"schedule"`. Same underlying trigger, two different vocabularies depending on which "trigger.type" you're reading. A webhook-triggered pipeline showed this directly: REST API said `"webhook"`, the compile-time value printed `"github_oauth"`.

**Verification method used:** added a temporary, zero-side-effect diagnostic job with no `when:` gate that just echoes `<< pipeline.trigger.type >>` to its own log — confirmed the literal value for both webhook and (waiting ~4h for the next 03:00 UTC firing) schedule triggers before trusting the fix, rather than shipping on documentation confidence alone. Removed once confirmed (PR #86).

**How to apply:** any `when:`/`equal:` gate keyed on `<< pipeline.trigger.type >>` (or similar built-in pipeline values) should be verified against a live pipeline of that trigger type, not assumed from REST API terminology — the two namespaces drift silently and CircleCI gives no error when the comparison is simply always-false.

**Related, separate finding:** `lucos/prune-images`'s avalon job times out under CircleCI's 10-minute no-output watchdog (silent `docker image prune -a -f` against ~3800 images) — tracked as `lucos_deploy_orb`#203, not part of this fix. Real disk usage still dropped ~102GB despite the CI step being killed, suggesting the underlying prune completes server-side regardless of the client-side CI failure.
