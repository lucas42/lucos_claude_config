---
name: Estate rollout repo discovery
description: Use GitHub API, not local grep, to find repos for estate-wide changes
type: feedback
---

For estate-wide changes (workflow updates, config rollouts), do NOT use `grep -rl` against local `~/sandboxes/` clones to discover target repos.

**Why:** Local clones are unreliable:
- Some repos may not be cloned at all (e.g. `lucos_antigravity_config`, `lucos_claude_config` were missed in the #34 rollout)
- Cloned repos may be stale — files added after the last pull won't appear in grep results

**How to apply:** Use the GitHub Contents API or code search to enumerate repos and their actual current file contents:
- List all known repos explicitly (from prior inventory or a maintained list)
- Check file existence via `repos/lucas42/{repo}/contents/.github/workflows/` 
- The `update_workflow.sh` pattern (fetch → transform → PUT) naturally handles stale/missing files gracefully — just run it against a comprehensive repo list and let it skip repos that don't have the file

**What went wrong:** In the #34 reusable-workflow estate rollout, 6 repos were missed because the discovery step used local filesystem grep. Caught and fixed post-rollout.
