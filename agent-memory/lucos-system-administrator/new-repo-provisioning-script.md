---
name: new-repo-provisioning-script
description: Standard provisioning script for new lucos repos — covers CI secrets, fork-PR approval policy, CircleCI webhook setup
metadata:
  type: reference
---

Run `~/.claude/scripts/provision-repo-ci-secrets.sh <repo-name>` when standing up any new lucos repo.

Covers in one shot:
1. `LUCOS_CI_PRIVATE_KEY` — full PEM extracted with Python (re.DOTALL), not grep|cut which truncates to header only
2. `LUCOS_CI_APP_ID`
3. `fork-pr-contributor-approval = first_time_contributors_new_to_github` (new repos default to `first_time_contributors` which blocks agent bot workflows)
4. **CircleCI follow** — `POST /api/v1.1/project/github/lucas42/{repo}/follow` registers the GitHub webhook. Without this, `ci/circleci:*` statuses never appear and all PRs stay blocked (discovered lucos_aithne standup 2026-06-09).
5. **Initial pipeline trigger on main** — follow registers webhook for future pushes only; existing commits on the repo are NOT retroactively built. Script now explicitly triggers main so the first build runs immediately. If PR branches were pushed before provisioning, trigger each manually: `curl -X POST -H 'Circle-Token: $TOKEN' https://circleci.com/api/v2/project/github/lucas42/{repo}/pipeline -d '{"branch":"<branch>"}'`

**What the script does NOT cover (still manual):**
- CircleCI SSH key (`docker-deploy@creds.l42.eu`) — private key not in agent environment; lucas42 adds it in CircleCI project settings → Additional SSH Keys → hostname `creds.l42.eu`
- Enabling "Allow auto-merge" in GitHub repo settings

**Verification:** after the next workflow run, check "Generate GitHub App token" step:
- `success` → both secrets valid ✓
- `skipped` → one or both empty — re-run script
- `failure` → non-empty but malformed — check script ran correctly

For supervised repos (no `unsupervisedAgentCode: true`): only lucas42's approval event triggers the auto-merge workflow; code-reviewer approval is intentionally skipped.

Created after lucos_dns_secondary standup (2026-06-07/08). CircleCI follow step added after lucos_aithne standup (2026-06-09).
