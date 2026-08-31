---
name: lucos-agent-76-fixture-based-quote-test
description: verify-teammate-quote's PROJECTS_DIR was made overridable via env var; tests/verify-teammate-quote now uses a synthetic fixture, no longer real session data
metadata:
  type: project
---

`lucos_agent`#76: RESOLVED 2026-08-31, PR #82 merged. `verify-teammate-quote`'s `PROJECTS_DIR` is now `"${PROJECTS_DIR:-<original hardcoded path>}"` — overridable, defaults unchanged for real callers. `tests/verify-teammate-quote` sets `PROJECTS_DIR` to `tests/fixtures/verify-teammate-quote/` and asserts against a synthetic fixture (`fixture-0001.jsonl`, sender `test-persona`) instead of the real 2026-05-14 incident session. Wired into `.circleci/config.yml`'s `test` job — no longer excluded.

**Why:** the old test hardcoded a real production session UUID that only exists on this machine, so it could never pass in CircleCI (`lucos_agent`#75 explicitly excluded it for that reason). The fixture satisfies "no real transcript data in the repo" **by construction** rather than by care — nothing in it comes from a real session.

**How to apply:** if `verify-teammate-quote`'s schema or matching logic ever changes, the fixture file needs updating to match (it exercises the same parsing path as real data, just synthetic content). See [[feedback_verify_teammate_quotes]] for the general quote-verification rule this tool supports.
