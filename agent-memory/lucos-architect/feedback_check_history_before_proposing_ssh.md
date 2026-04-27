---
name: Check repo history before proposing SSH/transport changes
description: Before proposing SSH/gateway/ProxyJump/transport changes, search closed issues+PRs for prior attempts at the same repo
type: feedback
---

Before proposing any change to SSH connection logic, gateway/ProxyJump configuration, or other transport-layer plumbing in a repo, **search the repo's closed issues and PRs for prior attempts at the same area**. Specifically look for: previous gateway/ProxyJump implementations, route-related incident issues, and any reverts thereof.

**Why:** First-pass proposals based purely on reading current code miss the lessons learned from previous attempts. In lucos_backups, PR #160 (April 2026) added gateway support to the Fabric Connection but missed the two raw `ssh`/`scp` subprocess paths in `copyFileTo`/`fileExistsRemotely` — partial application that produced unreliable behaviour. #185 reverted it, with lucas42 stating the principle: *"avoid ProxyJump complexity… if the gateway config is more gnarly than we first thought, remove it entirely and keep a predictable failure mode"*.

I missed this on first pass for lucos_backups#53 — proposed the same gateway model that had already failed, and team-lead had to point me at the history. Re-reading #185 led me to a much cleaner relay model (xwing → aurora rsync, no ProxyJump anywhere) that I'd have led with had I checked first.

**How to apply:** When the design touches SSH, transport, or any cross-cutting plumbing, before drafting the proposal:
1. `gh-as-agent search/issues q='repo:lucas42/<repo> is:closed <relevant-keyword>'` — look for prior issues
2. Read any closed PRs that touched the same files. Check for revert PRs.
3. Look for any "we tried this and it didn't work" comments from lucas42.
4. **In the proposal itself, explicitly acknowledge what was tried before and how the new design avoids the same failure mode.** This is load-bearing for trust — it shows the proposal isn't repeating known mistakes.

**Pattern recognition:** Cross-cutting code paths (multiple SSH call sites, multiple HTTP client constructors, multiple auth-header readers) are vulnerable to *partial application* — a change that updates some sites but not others, producing an inconsistent composite. When proposing changes to such areas, either centralise the logic first (so the change can land at one site) or be explicit about every call site that must be updated atomically.
