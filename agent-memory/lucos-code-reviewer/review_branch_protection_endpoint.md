---
name: review-branch-protection-endpoint
description: Use /branches/{branch} (not /branches/{branch}/protection) to read required status checks — the former returns 200 for bot Apps, the latter 403s
metadata:
  type: reference
---

`repos/{owner}/{repo}/branches/{branch}` returns 200 for `lucos-code-reviewer`'s App token and exposes `.protection.required_status_checks.contexts` — this is what Step 6 of `agents/workflows/review-pr.md` already uses and it's correct. The dedicated `.../branches/{branch}/protection` sub-endpoint 403s for at least some Apps (confirmed for `lucos-architect`'s token; not tested for mine, but treat as unreliable across Apps). `required_pull_request_reviews` comes back `null` at the `/branches/{branch}` level even when reviews *are* required — that field specifically needs the `/protection` path or an App with broader access (`lucos-site-reliability`'s token could read it per `lucos-architect`'s finding). So: required *status checks* — the `/branches/{branch}` path is reliable and sufficient. Required *review* settings — don't trust an absence there; ask SRE or treat the `lucos_repos` `branch-protection-enabled` convention (protection without requiring approvals) as the working assumption instead.

**Why this matters:** "only `lucos-system-administrator` can read branch protection" had been circulating as estate fact across multiple personas before `lucos-architect` traced it to hitting the wrong endpoint (`lucos_worlds#67`, 2026-08-06). Don't repeat a 403 from the `/protection` path as "bots can't read this" — try `/branches/{branch}` first.
