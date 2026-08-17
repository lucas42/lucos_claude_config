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

**Update 2026-08-17/18: `search/code` is not authoritative either — it silently missed a known-true hit.** Sweeping for `pipenv install` (no `--deploy`) across the estate, `GET search/code?q="pipenv install"+user:lucas42+filename:Dockerfile` returned 7 repos; `lucos-site-reliability` independently found 8 (different set — theirs included 2 *archived* repos as false positives and missed 2 live ones mine had). Reconciling both against a third, exhaustive method exposed the actual count as 8 live repos, only 5 of which both searches had agreed on. **The reliable method for anything that will drive real fix work:** (1) `users/lucas42/repos?per_page=100&type=owner`, filtered to `archived:false, fork:false`, for the definitive live-repo list; (2) per repo, `GET repos/{repo}/git/trees/{default_branch}?recursive=1` to list every file (catches subdirectory Dockerfiles like `ingestor/Dockerfile` that a naive top-level check misses, without needing to guess paths); (3) fetch each matching file's content directly via the Contents API and grep it yourself — never trust the search index's hit list as complete, and never trust an archived repo's presence in a hit list as meaning "still needs fixing." This is slower (63 tree calls + N content fetches vs. one search query) but is the only version worth citing in a ticket other people will act on.
