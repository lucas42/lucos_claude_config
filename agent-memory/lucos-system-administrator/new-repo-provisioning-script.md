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

Script also now sets (as of lucos_worlds standup, 2026-07-07):
6. Branch protection on `main` requiring `ci/circleci: lucos/build` (no approval/strict-mode requirement — those would block Dependabot auto-merge). Add test/CodeQL check names manually if the repo has them. **As of 2026-07-10 the script takes optional extra CLI args to override this default** — pass the correct required-check name(s) for repos with no `lucos/build` job (Component/library repos using `release-npm`/`release-pip`, e.g. `provision-repo-ci-secrets.sh lucos_aithne_jsclient "Analyze (javascript)"`). See [[component-repo-bootstrap-lucos-aithne-jsclient]].
7. `delete_branch_on_merge = true` **and** `allow_auto_merge = true` — both are plain repo-settings PATCHes the agent App already has permission for; there's no reason either was ever "still manual."

**What the script does NOT cover (still manual, genuinely — needs a human-held secret):**
- CircleCI SSH key (`docker-deploy@creds.l42.eu`) — this is the same unrestricted-including-production operational key documented in `lucos_creds`' `authorized_keys` (ADR-0002); agents must never hold it. lucas42 adds it in CircleCI project settings → SSH Keys → hostname `creds.l42.eu` (fingerprint `b7:75:7e:64:66:44:40:06:95:b4:ad:cd:07:a7:6f:08`, shared across all repos). Symptom when missing: `lucos/build` fails with `docker-deploy@creds.l42.eu: Permission denied (publickey)`.

**Verification:** after the next workflow run, check "Generate GitHub App token" step:
- `success` → both secrets valid ✓
- `skipped` → one or both empty — re-run script
- `failure` → non-empty but malformed — check script ran correctly

For supervised repos (no `unsupervisedAgentCode: true`): only lucas42's approval event triggers the auto-merge workflow; code-reviewer approval is intentionally skipped.

**Lesson (lucos_worlds standup, 2026-07-07):** before concluding "no provisioning script exists" and reimplementing PEM extraction / secret-setting / CircleCI-follow by hand, search `~/.claude/scripts/` specifically — that's where this script actually lives, not `~/sandboxes/lucos_agent/`. Wasted real effort re-deriving steps 1-4/6/9 by hand this session before finding the script already covered them (and had caught two steps — fork-pr-contributor-approval, branch protection — my manual pass had missed entirely).

Created after lucos_dns_secondary standup (2026-06-07/08). CircleCI follow step added after lucos_aithne standup (2026-06-09). Branch protection + auto-merge/delete-branch steps consolidated after lucos_worlds standup (2026-07-07).
