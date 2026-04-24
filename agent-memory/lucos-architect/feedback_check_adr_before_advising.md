---
name: Check the ADR before advising on v3 contract
description: On v3 APIs with formal ADRs, always read the ADR before answering contract questions — the history in issue comments may have been explicitly reversed
type: feedback
---

Before giving architectural advice on a v3 (or any post-ADR) API, read the relevant ADR and reconcile it against the earlier issue-thread discussions.

**Why:** On 2026-04-24, gave advice on lucos_media_metadata_api#189 from a "clean v3 contract" mental model without first reading `docs/adr/001-multi-value-fields.md`. The ADR explicitly reversed a position I had agreed to in #34 (single-value predicates should be scalars, not arrays). lucas42 caught the contradiction — I had agreed with him in March, then contradicted myself in April without flagging the ADR reversal as the reason. His question was specifically about whether the implementation matched the original #34 agreement; I needed to know the ADR history to answer properly.

**How to apply:** Whenever advising on contract/shape questions for an API that has a formal ADR (check `docs/adr/`):
1. Read the ADR end-to-end before writing advice.
2. If my prior comments in issue threads contradict the ADR, state the reversal explicitly — don't implicitly adopt one position over the other.
3. If the user's current concern echoes an earlier position that the ADR superseded, acknowledge that production experience may be validating the earlier concern — reversing an ADR is sometimes the right call, but it needs to be discussed explicitly, not slipped in.

Applies to all lucos projects with formal ADRs: lucos_media_metadata_api, lucos_repos, lucos_docker_mirror, lucos_arachne, lucos_docker_health, lucos_claude_config.
