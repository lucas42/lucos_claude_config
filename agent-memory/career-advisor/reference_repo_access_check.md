---
name: repo-access-check
description: How to actually check whether the career-advisor identity has access to a given repo — try the operation, don't infer from API permissions metadata
metadata:
  type: reference
---

When checking whether the career-advisor identity can read or write a specific GitHub repository, **try the operation directly** rather than inferring from API metadata.

**Don't**: call `gh-as-agent --app career-advisor repos/{owner}/{repo}` and conclude from the `permissions: {pull: false, push: false, …}` field that the identity lacks access. This field reflects something about the GitHub App installation context but does NOT reliably reflect what `git clone` (via SSH key) or `git-as-agent` can actually do.

**Do**: try the operation:

- **Read access**: `cd ~/sandboxes && git clone git@github.com:{owner}/{repo}.git` — succeeds if the SSH key on the machine has access (which it generally does, since SSH is configured at the user-account level).
- **Write access**: try a small commit + push via `git-as-agent --app career-advisor`. If the push lands, write access is good. If it's rejected with a permission error or branch-protection rule, you have a specific actionable error to address.

**Why**: Stated 2026-05-20 after I burned ~10 minutes inferring "no access" from a misleading API response, when SSH clone in fact worked first try. The disparity stems from GitHub Apps having one permission model (used by `gh-as-agent` API calls) and SSH-key access having another (used by `git clone`). They don't always agree.

Related: [[cv-application-privacy]] (which establishes lukeblaney_cv_tailored as the private outlet that needs the access check in the first place).
